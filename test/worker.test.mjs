import test, { afterEach } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const source = await readFile(new URL("../worker.js", import.meta.url), "utf8");
const { default: worker, RateLimiter } = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
);

const originalFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = originalFetch;
});

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

test("OPTIONS preflight returns 204", async () => {
  const response = await worker.fetch(
    new Request("https://example.test/chat", { method: "OPTIONS" }),
    {},
  );
  assert.equal(response.status, 204);
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
