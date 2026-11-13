import { CORS_HEADERS, jsonResponse } from "./worker/core/http.js";
import { MODEL } from "./worker/services/chat_provider.js";
import { handleChatRequest } from "./worker/routes/chat.js";
import { handleVisionRequest } from "./worker/routes/vision.js";

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    const url = new URL(request.url);

    if (url.pathname === "/vision") {
      return handleVisionRequest(request, env);
    }

    if (url.pathname === "/" && request.method === "GET") {
      return jsonResponse({
        success: true,
        status: "online",
        name: "BUJJI AI",
        service: "BUJJI AI API",
        version: "3.3",
        model: MODEL,
      });
    }

    if (url.pathname === "/chat") {
      return handleChatRequest(request, env);
    }

    return jsonResponse({
      success: false,
      error: "Endpoint not found.",
    }, 404);
  },
};
