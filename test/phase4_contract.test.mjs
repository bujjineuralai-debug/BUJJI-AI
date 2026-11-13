import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const read = (path) => readFile(new URL(`../${path}`, import.meta.url), "utf8");

test("local chat history is bounded, validated, restorable and clearable", async () => {
  const source = await read("lib/main.dart");
  assert.match(source, /static const String _chatStorageKey = 'bujji_chat_messages_v1'/);
  assert.match(source, /restored\.take\(100\)/);
  assert.match(source, /messages\.length > 100/);
  assert.match(source, /messages\.sublist\(messages\.length - 100\)/);
  assert.match(source, /Future<void> _restoreMessages\(\)/);
  assert.match(source, /Future<void> _persistMessages\(\)/);
  assert.match(source, /Future<void> _clearLocalChatHistory\(\)/);
  assert.match(source, /messages\.clear\(\)/);
  assert.match(source, /lastRequestId = null/);
});

test("diagnostics persist only a bounded, non-content request summary", async () => {
  const source = await read("lib/services/bujji_api_service.dart");
  const start = source.indexOf("static Future<void> _recordDiagnostic");
  const end = source.indexOf("static Future<void> clearDiagnostics");
  assert.ok(start >= 0 && end > start, "diagnostic writer must exist");
  const writer = source.slice(start, end);
  const keys = [...writer.matchAll(/^\s*'([A-Za-z]+)'\s*:/gm)].map((match) => match[1]);
  assert.deepEqual(keys, [
    "endpoint",
    "timestamp",
    "durationMs",
    "statusCode",
    "requestId",
    "outcome",
    "errorType",
  ]);
  for (const sensitiveKey of ["message", "prompt", "history", "image", "token", "email", "uid", "password"]) {
    assert.doesNotMatch(writer, new RegExp(`'${sensitiveKey}'\\s*:`, "i"));
  }
  assert.match(writer, /\.\.\.previous\.take\(49\)/);
  assert.match(source, /static Future<void> clearDiagnostics\(\)/);
  assert.match(source, /static Future<List<Map<String, dynamic>>> getRecentDiagnostics\(\)/);
});

test("Trace IDs flow from API responses into app diagnostics and UI state", async () => {
  const api = await read("lib/services/bujji_api_service.dart");
  const app = await read("lib/main.dart");
  const dashboard = await read("lib/menu/ai_diagnostics_screen.dart");
  assert.match(api, /'requestId': requestId/);
  assert.match(api, /requestId = decoded\['requestId'\]/);
  assert.match(app, /decoded\['requestId'\]/);
  assert.match(app, /lastRequestId = traceId/);
  assert.match(dashboard, /entry\['requestId'\]/);
  assert.match(dashboard, /Trace ID: \$traceId/);
});

test("Privacy Notice discloses provider processing and local-clear limitations", async () => {
  const notice = await read("lib/menu/privacy_security.dart");
  for (const required of [
    "Google Gemini",
    "Cloudflare AI",
    "Firebase Authentication",
    "IP address",
    "retention and processing",
    "do not delete data already sent",
    "does not provide an in-app account deletion flow",
    "authentication tokens",
  ]) {
    assert.ok(notice.toLowerCase().includes(required.toLowerCase()), `Privacy Notice missing: ${required}`);
  }
});

test("checked-in Worker configuration requires Firebase auth and rate limiting", async () => {
  const config = await read("wrangler.jsonc");
  assert.match(config, /"REQUIRE_RATE_LIMITING":\s*"true"/);
  assert.match(config, /"REQUIRE_FIREBASE_AUTH":\s*"true"/);
  assert.match(config, /"FIREBASE_PROJECT_ID":\s*"bujji-ai-2e2af"/);
  assert.match(config, /"RATE_LIMITER"/);
});

test("CORS source has an explicit origin allowlist and no wildcard grant", async () => {
  const worker = await read("worker.js");
  assert.match(worker, /CORS_ALLOWED_ORIGINS/);
  assert.match(worker, /allowedCorsOrigins/);
  assert.match(worker, /allowedCorsOrigins\(env\)\.includes\(origin\)/);
  assert.doesNotMatch(worker, /Access-Control-Allow-Origin\s*:\s*["']\*["']/i);
});
