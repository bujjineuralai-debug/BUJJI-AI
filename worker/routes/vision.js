import { jsonResponse } from "../core/http.js";

export async function handleVisionRequest(request, env) {

      if (request.method !== "POST") {
        return jsonResponse({ success: false, error: "Method not allowed." }, 405);
      }

      if (!env || !env.AI || typeof env.AI.run !== "function") {
        return jsonResponse({
          success: false,
          error: "Cloudflare AI binding is missing. Check the Worker AI binding.",
        }, 500);
      }

      const requestId = crypto.randomUUID();

      try {
        const body = await request.json();
        if (!body || typeof body !== "object" || Array.isArray(body)) {
          return jsonResponse({ success: false, error: "Invalid request body.", requestId }, 400);
        }

        const image = typeof body.image === "string" ? body.image : "";
        const question = typeof body.question === "string" ? body.question.trim() : "";

        if (!/^data:image\/(jpeg|jpg|png|webp);base64,/.test(image)) {
          return jsonResponse({ success: false, error: "A valid image is required.", requestId }, 400);
        }

        if (image.length > 7000000) {
          return jsonResponse({
            success: false,
            error: "Image is too large. Maximum image size is 5 MB.",
            requestId,
          }, 413);
        }

        if (!question || question.length > 1200) {
          return jsonResponse({
            success: false,
            error: "A question is required (maximum 1200 characters).",
            requestId,
          }, 400);
        }

        console.log("BUJJI Vision request started:", requestId);

        // Keep reasoning disabled so the model reserves its token budget for
        // the user-facing answer. The query task normally returns { answer }.
        const describeResultShape = (value) => {
          if (value === null || value === undefined) return "null";
          if (typeof value === "string") return `string(length=${value.length})`;
          if (typeof value !== "object") return typeof value;
          return `object(keys=${Object.keys(value).slice(0, 12).join(",") || "none"})`;
        };

        let result = await env.AI.run("@cf/moondream/moondream3.1-9B-A2B", {
          task: "query",
          image,
          question,
          reasoning: false,
          stream: false,
          max_tokens: 1200,
          temperature: 0.1,
        });

        const queryShape = describeResultShape(result);
        const queryAnswerType = result?.answer === null ? "null" : typeof result?.answer;
        const queryAnswerLength = typeof result?.answer === "string" ? result.answer.trim().length : 0;
        const queryFinishReason = result?.finish_reason ?? "not-provided";
        console.log("BUJJI Vision query diagnostics:", requestId, {
          result: queryShape,
          answerType: queryAnswerType,
          answerLength: queryAnswerLength,
          finishReason: queryFinishReason,
        });

        let answer = result && typeof result.answer === "string"
          ? result.answer.trim()
          : "";

        let captionShape = "not-run";
        let captionType = "not-run";
        let captionLength = 0;
        let captionFinishReason = "not-run";

        // A caption fallback makes the tool resilient if query returns no answer.
        if (!answer) {
          console.warn("BUJJI Vision query returned no answer; trying caption fallback:", requestId);
          result = await env.AI.run("@cf/moondream/moondream3.1-9B-A2B", {
            task: "caption",
            image,
            caption_length: "long",
            stream: false,
            max_tokens: 800,
            temperature: 0.1,
          });
          captionShape = describeResultShape(result);
          captionType = result?.caption === null ? "null" : typeof result?.caption;
          captionLength = typeof result?.caption === "string" ? result.caption.trim().length : 0;
          captionFinishReason = result?.finish_reason ?? "not-provided";
          console.log("BUJJI Vision caption diagnostics:", requestId, {
            result: captionShape,
            captionType,
            captionLength,
            finishReason: captionFinishReason,
          });
          answer = result && typeof result.caption === "string"
            ? result.caption.trim()
            : "";
        }

        if (!answer) {
          const detail = `query=${queryShape}; answerType=${queryAnswerType}; answerLength=${queryAnswerLength}; queryFinish=${queryFinishReason}; caption=${captionShape}; captionType=${captionType}; captionLength=${captionLength}; captionFinish=${captionFinishReason}`;
          console.error("BUJJI Vision returned no query answer or caption:", requestId, detail);
          return jsonResponse({
            success: false,
            error: "AI returned an empty vision result. Diagnostic details are attached.",
            detail,
            requestId,
          }, 502);
        }

        console.log("BUJJI Vision response successful:", requestId);
        return jsonResponse({ success: true, answer, requestId });
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        console.error("BUJJI Vision Error:", requestId, error);
        return jsonResponse({
          success: false,
          error: "Photo analysis failed.",
          detail: detail.slice(0, 300),
          requestId,
        }, 502);
      }
}
