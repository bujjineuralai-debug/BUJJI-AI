
const SYSTEM_PROMPT = `
You are BUJJI AI, a friendly, intelligent and reliable personal AI assistant.

PERSONALITY:
- Speak naturally, warmly, patiently and respectfully.
- Understand Telugu, English, Hindi and Malayalam.
- Understand Telugu-English mixed language and conversational Romanized Telugu.
- Never unnecessarily correct the user's grammar or spelling.
- Give clear, accurate and practical answers.
- Never pretend to perform actions you cannot perform.

TELUGU UNDERSTANDING:
- Treat Telugu written using English letters as Telugu, even when spelling is informal or inconsistent.
- Understand the meaning of the complete sentence, not just individual words.
- Recognize common spoken Telugu expressions, abbreviations and spelling variations.
- Understand conversational phrases such as:
  "Nuvvu ela unnav?" = "నువ్వు ఎలా ఉన్నావు?"
  "Nenu intiki velthunna" = "నేను ఇంటికి వెళ్తున్నాను."
  "Naaku ardham kaaledu" = "నాకు అర్థం కాలేదు."
  "Em chestunnav?" = "ఏం చేస్తున్నావు?"
  "Manam repu start cheddam" = "మనం రేపు ప్రారంభిద్దాం."
- Understand the user's actual intention before preparing the answer.
- Do not simply repeat, transliterate or translate the user's sentence.
- Answer the question directly and naturally, like a fluent Telugu speaker.
- When replying to Romanized Telugu, use natural Telugu script.
- Do not produce awkward Telugu by translating English word by word.
- If a Telugu sentence is genuinely unclear, politely ask what the user means instead of guessing.

STRICT LANGUAGE RULES:
- Reply in the language of the latest user message, following the detected language instruction.
- Do not let previous conversation language override the latest user message.
- English messages must receive English replies.
- Telugu messages must receive Telugu replies.
- Romanized Telugu messages must receive natural Telugu script replies unless the user asks otherwise.
- Hindi messages must receive Hindi replies in Devanagari script.
- Malayalam messages must receive Malayalam replies in Malayalam script.
- Short English greetings such as Hi, Hello, Hey and Hi Bujji must receive English replies.
- Do not confuse English with Malayalam or Romanized Telugu.
- If the language is unclear, use English.

CONVERSATION:
- Understand the conversation history when it is provided.
- Maintain context across messages.
- Avoid asking users to repeat information already provided.
- Ask only one clarification question when necessary.
- Remember the context of the current conversation when answering follow-up questions.

RESPONSE STYLE:
- Give direct, useful and relevant answers.
- Avoid unnecessary repetition and lengthy introductions.
- Use simple, natural language.
- Explain technical topics step by step.
- Adapt explanations to the user's understanding.
- Be honest about limitations.
- Do not invent facts or claim certainty when unsure.

IDENTITY:
- Your name is BUJJI AI.
- You are a personal AI assistant.
`;

const MODEL = "@cf/meta/llama-3.2-3b-instruct";
const MAX_MESSAGE_LENGTH = 4000;
const MAX_HISTORY_ITEMS = 12;
const MAX_HISTORY_MESSAGE_LENGTH = 4000;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "86400",
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS_HEADERS,
  });
}

// Romanized Telugu detection
const ROMAN_TELUGU_STRONG_WORDS = new Set([
  "nuvvu", "nuvve", "meeru", "nenu", "memu", "manam",
  "naaku", "naku", "neeku", "meeku", "vaallu", "vallu",
  "ela", "yela", "enti", "emiti", "enduku", "endhuku", "ekkada", "eppudu",
  "unnav", "unnava", "unnaru", "unnanu", "unnam", "unnayi", "unnai",
  "bagunnava", "bagunnanu", "bagunnam", "bagundi", "baagundi", "bagundhi",
  "avunu", "kaadu", "kadu", "kaadhu", "ledu", "ledhu", "undhi", "undi",
  "cheppu", "cheppandi", "cheppava", "cheyyi", "chey", "cheyyali", "chesa",
  "chesanu", "chesava", "chestha", "chestanu", "cheddam", "cheddham",
  "vastanu", "vastava", "vastundi", "vachindi", "vacchindi", "aindi", "ayindi",
  "vellanu", "vellava", "velthanu", "veldam", "pettu", "pettandi", "ivvu",
  "ivvandi", "chudu", "choopu", "kavali", "kavaali", "vaddu", "oddu",
  "ippudu", "intiki", "tarvata", "taruvatha", "inka", "telugu", "matladu",
  "matladandi", "namaskaram", "dhanyavadalu", "parledu", "sare",
]);

const ROMAN_TELUGU_SUPPORT_WORDS = new Set([
  "guru", "anna", "akka", "bujji", "na", "nee", "mee", "mana", "nundi",
  "nunchi", "tho", "lo", "ki", "kosam", "kuda", "kaani", "kani", "mari",
  "aithe", "ayithe", "ante", "andaru", "andariki", "ippatiki", "appudu",
  "roju", "manchi", "chala", "baaga", "konchem", "inka", "okati", "rendu",
  "moodu", "ekkadiki", "evaru", "evariki", "emi", "emaina", "leduga",
  "ledu", "chesi", "chesina", "chesuko", "cheyyandi", "avuthundi", "avutundi",
  "avvali", "avvadha", "avuthundhi", "vacchindi", "vachindi", "aipoindi",
  "aipoyindi", "aipotundi", "aipothundi", "undi", "undha", "unnaya",
  "kaavali", "kavali", "kudaradu", "kudurutunda", "telusa", "teliyadu",
  "ardham", "artham", "ayyindi", "ayindi", "sarega", "ledule", "vaddule",
]);

function detectLanguage(message) {
  const text = String(message || "").trim();

  if (!text) return "English";
  if (/[\u0C00-\u0C7F]/.test(text)) return "Telugu";
  if (/[\u0900-\u097F]/.test(text)) return "Hindi";
  if (/[\u0D00-\u0D7F]/.test(text)) return "Malayalam";

  const tokens = text.toLowerCase().match(/[a-z]+/g) || [];
  let score = 0;

  for (const token of tokens) {
    if (ROMAN_TELUGU_STRONG_WORDS.has(token)) {
      score += 2;
    } else if (ROMAN_TELUGU_SUPPORT_WORDS.has(token)) {
      score += 1;
    }
  }

  if (score >= 2) return "Telugu";
  return "English";
}

function cleanHistory(history) {
  if (!Array.isArray(history)) return [];

  return history
    .filter((item) =>
      item &&
      (item.role === "user" || item.role === "assistant") &&
      typeof item.content === "string" &&
      item.content.trim().length > 0
    )
    .slice(-MAX_HISTORY_ITEMS)
    .map((item) => ({
      role: item.role,
      content: item.content.trim().slice(0, MAX_HISTORY_MESSAGE_LENGTH),
    }));
}

function languageInstruction(language) {
  const replyStyle = language === "Telugu"
    ? "Use natural Telugu. If the user typed Telugu in Latin letters, reply in Telugu script."
    : language === "Hindi"
      ? "Use natural Hindi in Devanagari script."
      : language === "Malayalam"
        ? "Use natural Malayalam script."
        : "Use natural English.";

  return \`IMPORTANT: The latest user message has been detected as \${language}. \${replyStyle} Reply entirely in \${language}, unless the user explicitly asks for translation or another language. Do not follow the language used in older messages when it conflicts with the latest message.\`;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    const url = new URL(request.url);

    if (url.pathname === "/" && request.method === "GET") {
      return jsonResponse({
        success: true,
        status: "online",
        name: "BUJJI AI",
        service: "BUJJI AI API",
        version: "3.2",
        model: MODEL,
      });
    }

    if (url.pathname !== "/chat") {
      return jsonResponse({
        success: false,
        error: "Endpoint not found.",
      }, 404);
    }

    if (request.method !== "POST") {
      return jsonResponse({
        success: false,
        error: "Method not allowed.",
      }, 405);
    }

    const requestId = crypto.randomUUID();

    try {
      if (!env || !env.AI || typeof env.AI.run !== "function") {
        console.error("Cloudflare AI binding is missing:", requestId);
        return jsonResponse({
          success: false,
          error: "Cloudflare AI binding is missing.",
          requestId,
        }, 500);
      }

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

      if (typeof body.message !== "string" || body.message.trim().length === 0) {
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
          error: \`Message is too long. Maximum \${MAX_MESSAGE_LENGTH} characters.\`,
          requestId,
        }, 400);
      }

      const history = cleanHistory(body.history);
      const language = detectLanguage(message);

      const messages = [
        {
          role: "system",
          content: SYSTEM_PROMPT,
        },
        ...history,
        {
          role: "system",
          content: languageInstruction(language),
        },
        {
          role: "user",
          content: message,
        },
      ];

      console.log("BUJJI AI request started:", requestId);
      console.log("Detected language:", language);

      const result = await env.AI.run(MODEL, {
        messages,
        max_tokens: 1024,
        temperature: 0.6,
      });

      const reply = result && typeof result.response === "string"
        ? result.response.trim()
        : "";

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
  },
};
