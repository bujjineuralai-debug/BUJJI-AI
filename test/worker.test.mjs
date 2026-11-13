import test, { afterEach } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const source = await readFile(new URL("../worker.js", import.meta.url), "utf8");
const languageModuleSource = await readFile(
  new URL("../telugu_language_intelligence.js", import.meta.url),
  "utf8",
);
const { TELUGU_LANGUAGE_INTELLIGENCE_PROMPT } = await import(
  `data:text/javascript;base64,${Buffer.from(languageModuleSource).toString("base64")}`
);
const executableSource = source.replace(
  'import { TELUGU_LANGUAGE_INTELLIGENCE_PROMPT } from "./telugu_language_intelligence.js";',
  `const TELUGU_LANGUAGE_INTELLIGENCE_PROMPT = ${JSON.stringify(TELUGU_LANGUAGE_INTELLIGENCE_PROMPT)};`,
);
const { default: worker, RateLimiter } = await import(
  `data:text/javascript;base64,${Buffer.from(executableSource).toString("base64")}`
);

const originalFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = originalFetch;
});


function base64Url(value) {
  return Buffer.from(value).toString("base64url");
}

async function makeFirebaseToken(projectId = "bujji-ai-2e2af", overrides = {}) {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const publicJwk = await crypto.subtle.exportKey("jwk", pair.publicKey);
  publicJwk.kid = "phase4-test-key";
  publicJwk.alg = "RS256";
  publicJwk.use = "sig";

  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({
    alg: "RS256",
    typ: "JWT",
    kid: publicJwk.kid,
  }));
  const claims = base64Url(JSON.stringify({
    aud: projectId,
    iss: `https://securetoken.google.com/${projectId}`,
    sub: "phase4-test-user",
    iat: now,
    exp: now + 3600,
    auth_time: now,
    ...overrides,
  }));
  const signingInput = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    pair.privateKey,
    new TextEncoder().encode(signingInput),
  );
  return {
    token: `${signingInput}.${Buffer.from(signature).toString("base64url")}`,
    jwks: { keys: [publicJwk] },
  };
}

function envWithAi(run = async () => ({ response: "fallback reply" })) {
  return { AI: { run }, GEMINI_API_KEY: "test-key" };
}

function chatRequest(body, headers = { "content-type": "application/json" }) {
  return new Request("https://example.test/chat", {
    method: "POST",
    headers,
    body,
  });
}

test("OPTIONS preflight allows authenticated Flutter API requests", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/chat", {
      method: "OPTIONS",
      headers: {
        Origin: "https://app.example.test",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "content-type,authorization",
      },
    }),
    {},
  );
  assert.equal(response.status, 204);
  assert.equal(response.headers.get("Access-Control-Allow-Origin"), "*");
  assert.match(response.headers.get("Access-Control-Allow-Methods") || "", /POST/);
  assert.match(response.headers.get("Access-Control-Allow-Headers") || "", /Authorization/i);
});

test("unknown route returns 404", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/unknown"),
    {},
  );
  assert.equal(response.status, 404);
});

test("chat rejects malformed JSON with 400", async () => {
  const response = await worker.fetch(chatRequest("{"), envWithAi());
  assert.equal(response.status, 400);
  assert.equal((await response.json()).success, false);
});

test("chat rejects non-JSON content types with 415", async () => {
  const response = await worker.fetch(
    chatRequest("message=hello", { "content-type": "text/plain" }),
    envWithAi(),
  );
  assert.equal(response.status, 415);
});

test("chat rejects oversized request bodies with 413", async () => {
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "x".repeat(140_000) })),
    envWithAi(),
  );
  assert.equal(response.status, 413);
});

test("chat validates empty and oversized messages", async () => {
  const empty = await worker.fetch(
    chatRequest(JSON.stringify({ message: "   " })),
    envWithAi(),
  );
  assert.equal(empty.status, 400);

  const tooLong = await worker.fetch(
    chatRequest(JSON.stringify({ message: "x".repeat(4001) })),
    envWithAi(),
  );
  assert.equal(tooLong.status, 400);
});

test("Gemini success returns a correlated request id", async () => {
  globalThis.fetch = async (_url, options) => {
    const payload = JSON.parse(options.body);
    assert.ok(payload.systemInstruction.parts[0].text.includes("Romanized Telugu"));
    const systemPrompt = payload.systemInstruction.parts[0].text;
    assert.ok(systemPrompt.includes("TELUGU SCRIPT AND LETTER INVENTORY"));
    assert.ok(systemPrompt.includes("గుణింతాలు"));
    assert.ok(systemPrompt.includes("వత్తులు"));
    assert.ok(systemPrompt.includes("ఒత్తులు"));
    assert.ok(systemPrompt.includes("క్ష as a conjunct consonant form"));
    assert.ok(systemPrompt.includes("PRONOUNS, HONORIFICS AND ADDRESS"));
    return new Response(JSON.stringify({
      candidates: [{
        content: { parts: [{ text: "నమస్కారం! ఎలా సహాయం చేయాలి?" }] },
        finishReason: "STOP",
      }],
    }), { status: 200, headers: { "content-type": "application/json" } });
  };

  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "నమస్కారం" })),
    envWithAi(async () => { throw new Error("Fallback should not run"); }),
  );
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(data.success, true);
  assert.equal(data.reply, "నమస్కారం! ఎలా సహాయం చేయాలి?");
  assert.match(data.requestId, /^[0-9a-f-]{36}$/i);
});

test("Gemini failure uses the configured Llama fallback", async () => {
  globalThis.fetch = async () => new Response("temporary upstream failure", { status: 503 });
  let fallbackCalled = false;
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" })),
    envWithAi(async (model) => {
      fallbackCalled = true;
      assert.equal(model, "@cf/meta/llama-3.2-3b-instruct");
      return { response: "Fallback is working." };
    }),
  );
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(fallbackCalled, true);
  assert.equal(data.reply, "Fallback is working.");
  assert.ok(data.requestId);
});

test("required rate limiting fails closed when its binding is missing", async () => {
  const env = envWithAi();
  env.REQUIRE_RATE_LIMITING = "true";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" })),
    env,
  );
  assert.equal(response.status, 503);
});

test("chat returns 429 and Retry-After when the Durable Object denies a request", async () => {
  const env = envWithAi();
  env.REQUIRE_RATE_LIMITING = "true";
  env.RATE_LIMITER = {
    idFromName: (name) => name,
    get: () => ({
      fetch: async () => new Response(JSON.stringify({
        allowed: false,
        retryAfter: 17,
      }), { status: 200 }),
    }),
  };
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" })),
    env,
  );
  assert.equal(response.status, 429);
  assert.equal(response.headers.get("Retry-After"), "17");
});

test("Durable Object enforces an atomic fixed-window request limit", async () => {
  let state;
  const storage = {
    transaction: async (callback) => callback({
      get: async () => state,
      put: async (_key, value) => { state = value; },
    }),
  };
  const limiter = new RateLimiter({ storage });
  const call = () => limiter.fetch(new Request("https://rate-limit.internal/check", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ limit: 2, windowMs: 60_000 }),
  }));

  assert.equal((await (await call()).json()).allowed, true);
  assert.equal((await (await call()).json()).allowed, true);
  const denied = await call();
  const data = await denied.json();
  assert.equal(data.allowed, false);
  assert.ok(data.retryAfter >= 1);
});

test("required Firebase authentication rejects requests without a bearer token", async () => {
  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" })),
    env,
  );
  assert.equal(response.status, 401);
  assert.equal(response.headers.get("WWW-Authenticate"), "Bearer");
});

test("Firebase authentication verifies RS256 signature and project claims", async () => {
  const { token, jwks } = await makeFirebaseToken();
  globalThis.fetch = async (url) => {
    if (String(url).includes("securetoken@system.gserviceaccount.com")) {
      return new Response(JSON.stringify(jwks), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }
    return new Response(JSON.stringify({
      candidates: [{
        content: { parts: [{ text: "Authenticated response." }] },
        finishReason: "STOP",
      }],
    }), { status: 200, headers: { "content-type": "application/json" } });
  };

  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" }), {
      "content-type": "application/json",
      authorization: `Bearer ${token}`,
    }),
    env,
  );
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(data.reply, "Authenticated response.");
});

test("Firebase authentication rejects expired ID tokens", async () => {
  const now = Math.floor(Date.now() / 1000);
  const { token } = await makeFirebaseToken("bujji-ai-2e2af", {
    iat: now - 7200,
    exp: now - 3600,
  });
  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" }), {
      "content-type": "application/json",
      authorization: `Bearer ${token}`,
    }),
    env,
  );
  assert.equal(response.status, 401);
});

test("Firebase authentication rejects tokens issued for another project", async () => {
  const { token, jwks } = await makeFirebaseToken("another-firebase-project");
  globalThis.fetch = async () => new Response(JSON.stringify(jwks), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" }), {
      "content-type": "application/json",
      authorization: `Bearer ${token}`,
    }),
    env,
  );
  assert.equal(response.status, 401);
});

test("Firebase authentication rejects a token with an invalid RS256 signature", async () => {
  const signed = await makeFirebaseToken();
  const other = await makeFirebaseToken();
  globalThis.fetch = async () => new Response(JSON.stringify(other.jwks), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" }), {
      "content-type": "application/json",
      authorization: `Bearer ${signed.token}`,
    }),
    env,
  );
  assert.equal(response.status, 401);
});

test("Vision route also rejects requests without Firebase authentication", async () => {
  const env = envWithAi();
  env.REQUIRE_FIREBASE_AUTH = "true";
  env.FIREBASE_PROJECT_ID = "bujji-ai-2e2af";
  const response = await worker.fetch(
    new Request("https://example.test/vision", { method: "POST" }),
    env,
  );
  assert.equal(response.status, 401);
});

test("latest message language overrides the language of prior history", async () => {
  let captured;
  globalThis.fetch = async (_url, options) => {
    captured = JSON.parse(options.body);
    return new Response(JSON.stringify({
      candidates: [{
        content: { parts: [{ text: "I am doing well, thank you." }] },
        finishReason: "STOP",
      }],
    }), { status: 200, headers: { "content-type": "application/json" } });
  };

  const response = await worker.fetch(
    chatRequest(JSON.stringify({
      message: "Hello, how are you today?",
      history: [
        { role: "user", content: "నమస్కారం గురూ" },
        { role: "assistant", content: "నమస్కారం!" },
      ],
    })),
    envWithAi(),
  );
  assert.equal(response.status, 200);
  assert.match(
    captured.systemInstruction.parts[0].text,
    /detected as English/,
  );
  assert.equal(captured.contents[0].parts[0].text, "నమస్కారం గురూ");
  assert.equal(captured.contents[1].parts[0].text, "నమస్కారం!");
  assert.equal(captured.contents[2].parts[0].text, "Hello, how are you today?");
});

test("Roman Telugu, Telugu script and Hindi messages select their reply languages", async (tcase) => {
  const samples = [
    { message: "nenu baagunnanu", expected: "detected as Telugu" },
    { message: "nenu bagunnanu", expected: "detected as Telugu" },
    { message: "నమస్కారం", expected: "detected as Telugu" },
    { message: "नमस्ते", expected: "detected as Hindi" },
    { message: "How are you today?", expected: "detected as English" },
    { message: "nenu chala happy ga unna", expected: "detected as Telugu" },
    { message: "aap kaise hain", expected: "detected as Hindi" },
    { message: "njan sukham aanu", expected: "detected as Malayalam" },
    { message: "nenu happy ga unna", expected: "detected as Telugu" },
    { message: "నమస్కారం hello", expected: "detected as Telugu" },
  ];

  for (const sample of samples) {
    await tcase.test(sample.message, async () => {
      let systemText = "";
      globalThis.fetch = async (_url, options) => {
        systemText = JSON.parse(options.body).systemInstruction.parts[0].text;
        return new Response(JSON.stringify({
          candidates: [{
            content: { parts: [{ text: "Test reply." }] },
            finishReason: "STOP",
          }],
        }), { status: 200, headers: { "content-type": "application/json" } });
      };
      const response = await worker.fetch(
        chatRequest(JSON.stringify({ message: sample.message })),
        envWithAi(),
      );
      assert.equal(response.status, 200);
      assert.ok(
        systemText.includes(sample.expected),
        `Expected ${sample.expected} in language instruction.`,
      );
    });
  }
});

test("both Gemini and Llama failures return a safe server error", async () => {
  globalThis.fetch = async () => new Response("upstream unavailable", { status: 503 });
  const response = await worker.fetch(
    chatRequest(JSON.stringify({ message: "hello" })),
    envWithAi(async () => { throw new Error("fallback unavailable"); }),
  );
  const data = await response.json();
  assert.equal(response.status, 500);
  assert.equal(data.success, false);
  assert.ok(data.requestId);
  assert.equal(data.error, "Unable to process your request. Please try again.");
});

test("Vision validates image payload and returns an answer with Trace ID", async () => {
  let called = false;
  const env = envWithAi(async (model, input) => {
    called = true;
    assert.equal(model, "@cf/moondream/moondream3.1-9B-A2B");
    assert.equal(input.task, "query");
    assert.equal(input.image, "data:image/jpeg;base64,aGVsbG8=");
    return { answer: "ఇది ఒక పరీక్షా చిత్రం." };
  });
  const response = await worker.fetch(
    new Request("https://example.test/vision", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        image: "data:image/jpeg;base64,aGVsbG8=",
        question: "ఈ చిత్రంలో ఏముంది?",
      }),
    }),
    env,
  );
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(called, true);
  assert.equal(data.success, true);
  assert.equal(data.answer, "ఇది ఒక పరీక్షా చిత్రం.");
  assert.match(data.requestId, /^[0-9a-f-]{36}$/i);
});

test("Vision rejects missing and malformed image payloads", async () => {
  const env = envWithAi();
  const missing = await worker.fetch(
    new Request("https://example.test/vision", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ question: "What is this?" }),
    }),
    env,
  );
  assert.equal(missing.status, 400);

  const malformed = await worker.fetch(
    new Request("https://example.test/vision", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        image: "https://example.test/image.jpg",
        question: "What is this?",
      }),
    }),
    env,
  );
  assert.equal(malformed.status, 400);
});

test("Vision falls back to caption when query has no answer", async () => {
  let calls = 0;
  const env = envWithAi(async (_model, input) => {
    calls += 1;
    return input.task === "query"
      ? { answer: "" }
      : { caption: "A small wooden table." };
  });
  const response = await worker.fetch(
    new Request("https://example.test/vision", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        image: "data:image/jpeg;base64,aGVsbG8=",
        question: "What is this?",
      }),
    }),
    env,
  );
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(calls, 2);
  assert.equal(data.answer, "A small wooden table.");
});


test("chat audit stages share one Trace ID and never log user content", async () => {
  const originalLog = console.log;
  const auditRecords = [];
  console.log = (...args) => {
    for (const value of args) {
      if (typeof value !== "string") continue;
      try {
        const parsed = JSON.parse(value);
        if (parsed?.component === "bujji-worker") auditRecords.push(parsed);
      } catch {
        // Provider-selection diagnostics are intentionally not audit JSON.
      }
    }
  };

  const privateMessage = "phase4-private-user-message-must-not-appear-in-audit";
  try {
    globalThis.fetch = async () => new Response(JSON.stringify({
      candidates: [{
        content: { parts: [{ text: "Trace audit test response." }] },
        finishReason: "STOP",
      }],
    }), { status: 200, headers: { "content-type": "application/json" } });

    const response = await worker.fetch(
      chatRequest(JSON.stringify({
        message: privateMessage,
        history: [{ role: "user", content: "private prior history" }],
      })),
      envWithAi(async () => { throw new Error("Fallback should not run"); }),
    );
    const data = await response.json();

    assert.equal(response.status, 200);
    assert.equal(data.success, true);
    assert.ok(data.requestId);

    const completionEvents = auditRecords.filter((record) =>
      ["response_ready", "response_sent"].includes(record.event)
    );
    assert.deepEqual(
      completionEvents.map((record) => record.event),
      ["response_ready", "response_sent"],
    );
    assert.ok(completionEvents.every((record) => record.requestId === data.requestId));
    assert.ok(completionEvents.every((record) => record.component === "bujji-worker"));

    const serializedAudit = JSON.stringify(auditRecords);
    assert.equal(serializedAudit.includes(privateMessage), false);
    assert.equal(serializedAudit.includes("private prior history"), false);
    assert.equal(serializedAudit.includes("Trace audit test response."), false);
  } finally {
    console.log = originalLog;
  }
});
