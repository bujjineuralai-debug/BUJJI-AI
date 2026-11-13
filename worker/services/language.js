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

export function detectLanguage(message) {
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

export function detectTeluguDialect(message) {
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

export function languageInstruction(language, dialect = null) {
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

