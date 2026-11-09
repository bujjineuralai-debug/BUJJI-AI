const SYSTEM_PROMPT = `
You are BUJJI AI, a friendly, intelligent and reliable personal AI assistant.

PERSONALITY:
- Speak naturally, warmly, patiently and respectfully.
- Support all languages, not only the languages listed in this prompt.
- Give first-class support to Telugu, English and Hindi; also support Malayalam and other Indian and world languages.
- Understand mixed-language messages and languages written using Latin letters (Romanized / transliterated text).
- Never unnecessarily correct the user's grammar or spelling.
- Give clear, accurate and practical answers.
- Never pretend to perform actions you cannot perform.

LANGUAGE UNDERSTANDING:
- Identify the language and the user's intent from the complete latest message and its context, not from one isolated word.
- Recognize informal spelling, transliteration, abbreviations and regional conversational expressions.
- Romanized Telugu must be understood as Telugu and answered in natural Telugu script.
- If the user writes Telugu using Latin letters, write the entire reply in Telugu script. Do not repeat or quote the user's Romanized Telugu words or sentences in Latin letters; express their meaning naturally in Telugu script instead.
- For example, to Nuvvu ela unnav?, reply naturally with నేను బాగున్నాను. మీరు ఎలా ఉన్నారు? and never begin by echoing Nuvvu ela unnav.
- When the user sends the Romanized Telugu acknowledgement sare, understand it as సరే and reply with a short, natural acknowledgement such as సరే! or అలాగే!.
- Never transliterate sare as నీ సారే, and do not add unrelated or invented words to a short acknowledgement.
- Romanized Hindi must be understood as Hindi and answered in natural Devanagari Hindi.
- Romanized Malayalam must be understood as Malayalam and answered in natural Malayalam script.
- For every other language, reply in that language and use its normal writing system when you can identify it.
- If the user mixes languages, normally reply in the main language of the latest message while naturally retaining necessary names or terms.
- Do not simply repeat, transliterate or translate the user's sentence. Understand the actual intention and answer it.
- Do not produce awkward translations word by word.
- If a message is genuinely ambiguous, ask one short clarification question instead of guessing.

STRICT LANGUAGE RULES:
- Reply in the language of the latest user message.
- Do not let previous conversation language override the latest user message.
- Short English greetings such as Hi, Hello, Hey and Hi Bujji must receive English replies.
- When the language is uncertain, infer it from context. If it remains unclear, use a brief neutral clarification rather than confidently forcing English.

CONVERSATION:
- Understand the conversation history when it is provided.
- Maintain context across messages.
- Avoid asking users to repeat information already provided.
- Ask only one clarification question when necessary.

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

const ROMAN_TELUGU_WORDS = new Set([
  "nuvvu", "nuvve", "meeru", "nenu", "memu", "manam", "naaku", "naku",
  "neeku", "meeku", "vaallu", "vallu", "ela", "yela", "enti", "emiti",
  "enduku", "endhuku", "ekkada", "eppudu", "unnav", "unnava", "unnaru",
  "unnanu", "unnam", "unnayi", "unnai", "bagunnava", "bagunnanu", "bagundi",
  "baagundi", "bagundhi", "avunu", "kaadu", "kadu", "kaadhu", "ledu", "ledhu",
  "undhi", "undi", "cheppu", "cheppandi", "cheppava", "cheyyi", "chey",
  "cheyyali", "chesa", "chesanu", "chesava", "chestha", "chestanu", "cheddam",
  "cheddham", "vastanu", "vastava", "vastundi", "vachindi", "vacchindi", "aindi",
  "ayindi", "vellanu", "vellava", "velthanu", "veldam", "pettu", "pettandi",
  "ivvu", "ivvandi", "chudu", "choopu", "kavali", "kavaali", "vaddu", "oddu",
  "ippudu", "intiki", "tarvata", "taruvatha", "inka", "telugu", "matladu",
  "matladandi", "namaskaram", "dhanyavadalu", "parledu", "sare", "guru", "anna",
  "akka", "bujji", "na", "nee", "mee", "mana", "nundi", "nunchi", "tho", "lo",
  "kosam", "kuda", "kaani", "kani", "mari", "aithe", "ayithe", "ante", "andaru",
  "andariki", "ippatiki", "appudu", "roju", "manchi", "chala", "baaga", "konchem",
  "okati", "rendu", "moodu", "ekkadiki", "evaru", "evariki", "emi", "emaina",
  "chesi", "chesina", "chesuko", "cheyyandi", "avuthundi", "avutundi", "avvali",
  "avvadha", "avuthundhi", "aipoindi", "aipoyindi", "aipotundi", "aipothundi",
  "undha", "unnaya", "kudaradu", "kudurutunda", "telusa", "teliyadu", "ardham",
  "artham", "ayyindi", "sarega", "ledule", "vaddule", "kada", "kadha",
]);

const ROMAN_TELUGU_SINGLE_WORDS = new Set([
  "sare", "avunu", "kaadu", "kadu", "kaadhu", "ledu", "ledhu",
]);

const ROMAN_HINDI_WORDS = new Set([
  "namaste", "namaskar", "haan", "han", "nahi", "nahin", "main", "mein", "hum",
  "tum", "aap", "mujhe", "mujhko", "mera", "meri", "mere", "tera", "teri", "aapka",
  "kaise", "kaisa", "kaisi", "kya", "kyun", "kyon", "kab", "kahan", "kidhar",
  "hai", "hain", "hoon", "hun", "ho", "tha", "thi", "the", "hoga", "hogi", "honge",
  "kar", "karo", "karein", "karna", "karunga", "karungi", "chahiye", "sakta", "sakti",
  "sakte", "raha", "rahi", "rahe", "gaya", "gayi", "gaye", "acha", "accha", "achha",
  "theek", "thik", "bahut", "bohot", "dhanyavaad", "shukriya", "kripya", "matlab",
  "samajh", "samjha", "batao", "bolo", "suno", "dekho", "abhi", "phir", "kyunki",
  "lekin", "aur", "yaar", "bhai", "dost", "ghar", "paani", "kaam", "karo",
]);

const ROMAN_MALAYALAM_WORDS = new Set([
  "njan", "njaan", "ningal", "ningalkku", "namukku", "enikku", "enikk", "ente",
  "ninte", "ningalude", "avan", "aval", "ivide", "avide", "evide", "entha", "enthanu",
  "aano", "aanu", "alla", "ille", "undo", "undu", "illa", "venam", "venda", "mathi",
  "sukham", "sugham", "nanni", "chetta", "chechi", "etta", "mone", "mole", "poyi",
  "varum", "vannu", "pokam", "pokan", "kazhicho", "kazhichu", "parayu", "parayoo",
  "ariyilla", "ariyam", "shari", "sheri", "ippo", "ippol", "pinne", "nalla", "valare",
  "kurachu", "enthaanu", "engane", "enthina", "ivideya", "samsarikkam",
]);

const ENGLISH_WORDS = new Set([
  "a", "about", "after", "again", "all", "am", "an", "and", "any", "are",
  "as", "at", "be", "because", "been", "before", "being", "but", "by", "can",
  "could", "day", "did", "do", "does", "doing", "down", "even", "for", "from",
  "get", "give", "good", "great", "had", "has", "have", "he", "hello", "her",
  "here", "hey", "him", "his", "how", "i", "if", "in", "is", "it", "its",
  "just", "know", "like", "little", "may", "me", "more", "most", "much", "my",
  "need", "not", "now", "of", "on", "one", "or", "our", "out", "please",
  "really", "say", "see", "she", "should", "so", "some", "thank", "thanks",
  "that", "the", "their", "them", "then", "there", "these", "they", "thing",
  "think", "this", "those", "time", "to", "today", "too", "up", "us", "very",
  "was", "we", "well", "were", "what", "when", "where", "which", "who", "why",
  "will", "with", "would", "yes", "you", "your"
]);

const ENGLISH_SINGLE_WORDS = new Set([
  "hi", "hello", "hey", "thanks", "thankyou", "please", "okay", "ok",
  "good", "great", "sorry", "welcome", "bye", "goodbye", "yes", "no"
]);

function scoreWords(tokens, dictionary) {
  let score = 0;

  for (const token of tokens) {
    if (dictionary.has(token)) {
      score += 1;
    }
  }

  return score;
}

function detectLanguage(message) {
  const text = String(message || "").trim();

  if (!text) return "Auto-detect";

  const teluguChars = (text.match(/[\u0C00-\u0C7F]/g) || []).length;
  const devanagariChars = (text.match(/[\u0900-\u097F]/g) || []).length;
  const malayalamChars = (text.match(/[\u0D00-\u0D7F]/g) || []).length;

  if (teluguChars > 0 || devanagariChars > 0 || malayalamChars > 0) {
    if (teluguChars >= devanagariChars && teluguChars >= malayalamChars) {
      return "Telugu";
    }

    if (devanagariChars >= malayalamChars) {
      return "Hindi";
    }

    return "Malayalam";
  }

  const tokens = text.toLowerCase().match(/[a-z]+/g) || [];

  if (tokens.length === 0) return "Auto-detect";

  const normalized = tokens.map((token) =>
    token.replace(/(.)\1{2,}/g, "$1$1")
  );
  const shortText = normalized.join(" ");

  if (/^(hi|hello|hey|hi bujji|hello bujji)$/.test(shortText)) {
    return "English";
  }

  const englishScore = scoreWords(normalized, ENGLISH_WORDS);
  const teluguScore = scoreWords(normalized, ROMAN_TELUGU_WORDS);
  const hindiScore = scoreWords(normalized, ROMAN_HINDI_WORDS);
  const malayalamScore = scoreWords(normalized, ROMAN_MALAYALAM_WORDS);

  const highestNonEnglishScore = Math.max(
    teluguScore,
    hindiScore,
    malayalamScore
  );

  if (
    normalized.length === 1 &&
    ROMAN_TELUGU_SINGLE_WORDS.has(normalized[0])
  ) {
    return "Telugu";
  }

  if (englishScore >= 2 && englishScore > highestNonEnglishScore) {
    return "English";
  }

  if (highestNonEnglishScore < 2) {
    if (normalized.length === 1 && ENGLISH_SINGLE_WORDS.has(normalized[0])) {
      return "English";
    }
    return "Auto-detect";
  }

  if (teluguScore === highestNonEnglishScore) return "Telugu";
  if (hindiScore === highestNonEnglishScore) return "Hindi";

  return "Malayalam";
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
  if (language === "Auto-detect") {
    return "IMPORTANT: Identify the language of the latest user message itself, including its meaning, grammar, and common words. Reply in that same language and its normal writing system. Support as many languages as possible, including languages written in Latin letters and mixed-language messages. Use earlier conversation only to resolve genuine ambiguity; NEVER let an older message language override a clearly identifiable latest message. If the latest message is clearly English, reply in English even when all earlier messages were in another language. If genuinely ambiguous, ask one brief clarification.";
  }

  const replyStyle = language === "Telugu"
    ? "Use natural Telugu. If the user typed Telugu in Latin letters, reply in Telugu script."
    : language === "Hindi"
      ? "Use natural Hindi in Devanagari script, including when the user typed Hindi in Latin letters."
      : language === "Malayalam"
        ? "Use natural Malayalam in Malayalam script, including when the user typed Malayalam in Latin letters."
        : "Use natural English.";

  return `IMPORTANT: The latest user message has been detected as ${language}. ${replyStyle} Reply entirely in ${language}, unless the user explicitly asks for translation or another language. Do not follow the language used in older messages when it conflicts with the latest message.`;
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
        version: "3.3",
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
