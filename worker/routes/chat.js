import { jsonResponse, MAX_MESSAGE_LENGTH, cleanHistory } from "../core/http.js";
import { detectLanguage, detectTeluguDialect, languageInstruction } from "../services/language.js";
import { runChatModel } from "../services/chat_provider.js";

export async function handleChatRequest(request, env) {
  if (request.method !== "POST") {
    return jsonResponse({ success: false, error: "Method not allowed." }, 405);
  }
    const requestId = crypto.randomUUID();

    try {
      let body;

      try {
        body = await request.json();
      } catch {
        return jsonResponse({
          success: false,
          error: "Invalid JSON request.",
          requestId,
        }, 400);
      }

      if (!body || typeof body !== "object" || Array.isArray(body)) {
        return jsonResponse({
          success: false,
          error: "Invalid request body.",
          requestId,
        }, 400);
      }

      if (
        typeof body.message !== "string" ||
        body.message.trim().length === 0
      ) {
        return jsonResponse({
          success: false,
          error: "Please enter a message.",
          requestId,
        }, 400);
      }

      const message = body.message.trim();

      if (message.length > MAX_MESSAGE_LENGTH) {
        return jsonResponse({
          success: false,
          error: `Message is too long. Maximum ${MAX_MESSAGE_LENGTH} characters.`,
          requestId,
        }, 400);
      }

      const history = cleanHistory(body.history);
      const language = detectLanguage(message);
      const dialect = language === "Telugu" ? detectTeluguDialect(message) : null;

      const messages = [
        {
          role: "system",
          content: SYSTEM_PROMPT,
        },
        ...history,
        {
          role: "system",
          content: languageInstruction(language, dialect),
        },
        {
          role: "user",
          content: message,
        },
      ];

      console.log("BUJJI AI request started:", requestId);
      console.log("Detected language:", language);
      if (dialect) console.log("Detected Telugu dialect hint:", dialect);

      const reply = await runChatModel(env, messages);

      if (!reply) {
        console.error("BUJJI AI returned an empty response:", requestId);

        return jsonResponse({
          success: false,
          error: "AI did not return a valid response.",
          requestId,
        }, 502);
      }

      console.log("BUJJI AI response successful:", requestId);

      return jsonResponse({
        success: true,
        name: "BUJJI AI",
        reply,
        requestId,
      });
    } catch (error) {
      console.error("BUJJI AI Error:", requestId, error);

      return jsonResponse({
        success: false,
        error: "Unable to process your request. Please try again.",
        requestId,
      }, 500);
    }
}
