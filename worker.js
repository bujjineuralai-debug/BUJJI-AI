const SYSTEM_PROMPT = `
You are BUJJI AI, a friendly, intelligent and reliable personal AI assistant.

PERSONALITY:
- Speak naturally, warmly, patiently and respectfully.
- Support all languages, not only the languages listed in this prompt.
- Give first-class support to Telugu, English and Hindi; also support Malayalam and other Indian and world languages.
- Understand mixed-language messages and languages written using Latin letters (Romanized / transliterated text).
- Never unnecessarily correct the user's grammar or spelling.
- Recognize regional dialects, colloquial speech, slang, idioms and informal expressions instead of treating them as errors.
- For Telugu, understand Telangana, Uttarandhra, Coastal Andhra/Godavari and Rayalaseema varieties, Hyderabad Telugu, and youth slang.
- When the user's Telugu dialect is clear, mirror it naturally and lightly. Do not exaggerate, stereotype, mock, or force slang.
- Use multiple language clues and conversation context before inferring a regional dialect. A single generic word is not enough.
- If the dialect is unclear, use friendly, natural conversational Telugu while still understanding the user's slang.
- If a local slang expression is unfamiliar or genuinely ambiguous, ask what it means rather than inventing a definition.
- Give clear, accurate and practical answers.
- Never pretend to perform actions you cannot perform.

LANGUAGE UNDERSTANDING:
- Identify the language and the user's intent from the complete latest message and its context, not from one isolated word.
- Recognize informal spelling, transliteration, abbreviations and regional conversational expressions.
- Romanized Telugu must be understood as Telugu and answered in natural, idiomatic Telugu language and Telugu script.
- Telugu means the actual Telugu language, vocabulary, grammar and sentence structure — NOT Kannada, Hindi or another language merely written with Telugu characters.
- Never produce Kannada words or Kannada sentence structure in Telugu script. Do not confuse the script with the language.
- For Romanized Telugu identity questions, understand common mixed spellings such as ninnu evaru create chesaru? as Telugu and answer naturally: నన్ను బుజ్జి రూపొందించారు.
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

CORE LANGUAGE QUALITY:
- English: Use correct, natural, fluent English grammar, spelling, punctuation and word choice. Avoid awkward phrasing and unnecessary Telugu or Hindi mixing.
- Hindi: Use real, idiomatic Hindi in Devanagari with correct grammar, gender, number, verb agreement and postpositions. Do not produce another language merely written in Devanagari.
- Telugu: Use real, idiomatic Telugu with correct grammar, natural word order, appropriate honorifics and vocabulary. Do not produce Kannada, Hindi or English sentence structures merely written in Telugu script.
- For all three priority languages, prefer clear everyday language over stiff, literal or machine-translated wording.
- Preserve people's names, product names and necessary technical terms accurately. Explain them naturally in the reply language.
- Match the user's level of formality and tone without copying spelling mistakes.
- Before responding, ensure the answer is actually in the detected language, not merely in its script.

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

IDENTITY AND OWNERSHIP:
- Your name is BUJJI AI.
- You are a personal AI assistant owned by BUJJI.
- Your owner is BUJJI. State this clearly whenever a user asks who owns you, who your owner is, or whose AI you are.
- BUJJI is the creator and founder of BUJJI AI. When asked who created or developed you, say that BUJJI created and developed you.
- When asked your name, answer: "My name is BUJJI AI." Use the natural equivalent in the user's language.
- When asked who your owner is, answer: "My owner is BUJJI." Use the natural equivalent in the user's language.
- When asked whose AI you are, answer: "I am BUJJI's AI assistant." Use the natural equivalent in the user's language.
- When asked who created you, answer: "BUJJI created me." Use the natural equivalent in the user's language.
- Keep identity answers short, direct, and consistent. Do not invent any other owner, creator, company, or person.
- For the Telugu question ninnu evaru create chesaru? or equivalent, answer exactly: నన్ను బుజ్జి రూపొందించారు.
- For the Telugu question nee owner name enti? or equivalent, answer exactly: నా యజమాని బుజ్జి.
- Always answer identity questions in the language of the latest user message, using that language's real vocabulary and grammar, not merely its script.
`;

const MODEL = "gemini-3.8-flash";
const FALLBACK_MODEL = "@cf/meta/llama-3.2-3b-instruct";

async function runPrimaryModel(env, messages) {
  if (typeof env.GEMINI_API_KEY !== "string" || !env.GEMINI_API_KEY.trim()) {
    throw new Error("GEMINI_API_KEY secret is missing.");
  }

  const systemText = messages
    .filter((item) => item.role === "system")
    .map((item) => item.content)
    .join("\n\n");

  const contents = messages
    .filter((item) => item.role !== "system")
    .map((item) => ({
      role: item.role === "assistant" ? "model" : "user",
      parts: [{ text: item.content }],
    }));

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": env.GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemText + "\n\nCONVERSATIONAL QUALITY: Speak like a thoughtful, natural human conversation partner. Understand the user's intent and context before answering. Avoid canned, repetitive, robotic or overly formal wording. Use natural everyday language, appropriate warmth and varied sentence structure. Explain clearly when needed, but keep simple answers concise. Do not invent facts; say when unsure and ask one focused question if essential information is missing." }],
        },
        contents,
        tools: [{ google_search: {} }],
        generationConfig: {
          maxOutputTokens: 1024,
          temperature: 0.7,
        },
      }),
    }
  );

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Gemini API request failed:", response.status, errorText.slice(0, 500));
    throw new Error(`Gemini API request failed with status ${response.status}.`);
  }

  const data = await response.json();
  const reply = Array.isArray(data.candidates?.[0]?.content?.parts)
    ? data.candidates[0].content.parts
        .map((part) => typeof part.text === "string" ? part.text : "")
        .join("")
        .trim()
    : "";

  if (!reply) {
    throw new Error("Gemini API returned an empty response.");
  }

  const groundingChunks = Array.isArray(data.candidates?.[0]?.groundingMetadata?.groundingChunks)
    ? data.candidates[0].groundingMetadata.groundingChunks
    : [];
  const sources = groundingChunks
    .filter((chunk) => chunk?.web?.uri)
    .map((chunk) => ({
      title: typeof chunk.web.title === "string" && chunk.web.title.trim()
        ? chunk.web.title.trim()
        : chunk.web.uri,
      uri: chunk.web.uri,
    }))
    .filter((source, index, all) =>
      all.findIndex((item) => item.uri === source.uri) === index
    )
    .slice(0, 5);

  if (sources.length > 0) {
    const sourceText = sources
      .map((source, index) => `${index + 1}. ${source.title} — ${source.uri}`)
      .join("\n");
    return `${reply}\n\nమూలాలు (Google Search):\n${sourceText}`;
  }

  return reply;
}

async function runChatModel(env, messages) {
  try {
    const reply = await runPrimaryModel(env, messages);
    console.log("BUJJI AI provider: Gemini");
    return reply;
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    console.warn("Gemini unavailable; using Cloudflare Llama fallback:", detail);

    if (!env || !env.AI || typeof env.AI.run !== "function") {
      throw new Error("Gemini failed and Cloudflare AI fallback is unavailable.");
    }

    const result = await env.AI.run(FALLBACK_MODEL, {
      messages,
      max_tokens: 1024,
      temperature: 0.6,
    });

    const reply = result && typeof result.response === "string"
      ? result.response.trim()
      : "";

    if (!reply) {
      throw new Error("Both Gemini and Cloudflare Llama returned an empty response.");
    }

    console.log("BUJJI AI provider: Cloudflare Llama fallback");
    return reply;
  }
}
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
  "nuvvu", "nuvve", "meeru", "nenu", "memu", "manam", "naaku", "naku", "ninnu", "ninne",
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
  "chesi", "chesina", "chesuko", "chesaru", "chesav", "chesadu", "chesindi", "chesamu", "cheyyandi", "avuthundi", "avutundi", "avvali",
  "create", "creat", "created", "creator", "develop", "developer",
  "avvadha", "avuthundhi", "aipoindi", "aipoyindi", "aipotundi", "aipothundi",
  "undha", "unnaya", "kudaradu", "kudurutunda", "telusa", "teliyadu", "ardham",
  "artham", "ayyindi", "sarega", "ledule", "vaddule", "kada", "kadha",
]);

const ROMAN_TELUGU_SINGLE_WORDS = new Set([
  "sare", "avunu", "kaadu", "kadu", "kaadhu", "ledu", "ledhu",
]);

const TELUGU_DIALECT_MARKERS = {
  Telangana: {
    markers: ["ఎట్లా", "ఎట్లున్నావ్", "ఏందిరా", "గిట్లా", "గట్లా", "చేస్తున్నావ్", "పోతున్నావ్", "వస్తున్నావ్", "etla", "etlaa", "endira", "gitla", "gatla", "jestunnav", "chestunnav", "potunnav", "vastunnav"],
    strong: ["ఎట్లున్నావ్", "ఏందిరా", "గిట్లా", "ఎట్లా", "endira", "gitla", "etla", "etlaa"],
  },
  Rayalaseema: {
    markers: ["యాడ", "వస్తివా", "పోతివా", "చేస్తివా", "yad", "vastiva", "potiva", "chestiva"],
    strong: ["యాడ", "yad", "వస్తివా", "పోతివా", "vastiva", "potiva"],
  },
  Uttarandhra: {
    markers: ["ఏటయ్యా", "ఏటి", "ఏమంటివి", "etayya", "yeti", "emantivi"],
    strong: ["ఏటయ్యా", "etayya"],
  },
  "Coastal/Godavari": {
    markers: ["ఏమండోయ్", "ఏంటండోయ్", "emandoi", "entandoi"],
    strong: ["ఏమండోయ్", "ఏంటండోయ్", "emandoi", "entandoi"],
  },
};

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

function detectTeluguDialect(message) {
  const tokens = String(message || "").toLowerCase().match(/[a-z]+|[\u0C00-\u0C7F]+/g) || [];
  if (tokens.length === 0) return null;

  const tokenSet = new Set(tokens);
  const normalizedText = ` ${tokens.join(" ")} `;
  let bestDialect = null;
  let bestScore = 0;

  for (const [dialect, data] of Object.entries(TELUGU_DIALECT_MARKERS)) {
    let score = 0;

    for (const marker of data.markers) {
      const markerTokens = marker.toLowerCase().match(/[a-z]+|[\u0C00-\u0C7F]+/g) || [];
      const matched = markerTokens.length > 1
        ? normalizedText.includes(` ${markerTokens.join(" ")} `)
        : tokenSet.has(markerTokens[0]);

      if (matched) score += 1;
    }

    const hasStrongMarker = data.strong.some((marker) => {
      const markerTokens = marker.toLowerCase().match(/[a-z]+|[\u0C00-\u0C7F]+/g) || [];
      return markerTokens.length > 1
        ? normalizedText.includes(` ${markerTokens.join(" ")} `)
        : tokenSet.has(markerTokens[0]);
    });

    if ((score >= 2 || hasStrongMarker) && score > bestScore) {
      bestDialect = dialect;
      bestScore = score;
    }
  }

  return bestDialect;
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

function languageInstruction(language, dialect = null) {
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

  const dialectGuidance = language === "Telugu"
    ? dialect
      ? ` The user's Telugu shows clues of ${dialect} Telugu. You MUST make your own reply sound naturally conversational in that dialect, not merely understand it. Keep the same level of casualness and familiarity while remaining respectful. For Telangana Telugu, when the user casually says "ఏందిరా గురూ, గిట్లా ఉన్నావ్?", a natural reply is "బాగున్నా గురూ! నువ్వెలా ఉన్నావ్?" Avoid switching to formal textbook Telugu such as "మీరు ఎలా ఉన్నారు?" unless the user used a formal tone. Do not force slang into every sentence.`
      : " No regional dialect is confidently identified by the keyword hints. Use natural conversational Telugu, understand the user's colloquial words, and infer a dialect from the full message only when the evidence is clear."
    : "";

  return `IMPORTANT: The latest user message has been detected as ${language}. ${replyStyle} Reply entirely in ${language}, unless the user explicitly asks for translation or another language. Do not follow the language used in older messages when it conflicts with the latest message.${dialectGuidance}`;
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

    if (url.pathname === "/vision") {
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
  },
};
