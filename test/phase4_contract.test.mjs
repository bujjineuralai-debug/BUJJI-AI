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
  ]);
  // errorType is deliberately written as a conditional map entry.
  assert.ok(
    writer.includes("if (errorType != null) 'errorType': errorType,"),
    "errorType must be stored only as a conditional diagnostic field",
  );
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

test("Voice Translation uses the shared authenticated Worker transport", async () => {
  const source = await read("lib/menu/menu_features.dart");
  assert.match(source, /BujjiApiService\.postJson\(/);
  assert.match(source, /import '\.\.\/services\/bujji_api_service\.dart';/);
  assert.doesNotMatch(source, /HttpClient\s*\(/);
  assert.doesNotMatch(source, /postUrl\s*\(/);
});

test("optional DOB can be removed from the user's Firestore profile", async () => {
  const profile = await read("lib/menu/my_account_screen.dart");
  assert.match(profile, /clearDateOfBirth\s*=\s*false/);
  assert.match(profile, /FieldValue\.delete\(\)/);
  assert.match(profile, /tooltip:\s*'Clear date of birth'/);
  assert.match(profile, /clearDateOfBirth:\s*_dateOfBirth == null/);
});

test("AI Diagnostics is visible only in debug/development builds", async () => {
  const menu = await read("lib/menu/menu_home.dart");
  assert.match(menu, /import 'package:flutter\/foundation\.dart' show kDebugMode;/);
  assert.match(menu, /final visibleItems = kDebugMode/);
  assert.match(menu, /items\.where\(\(item\) => item\.title != 'AI Diagnostics'\)/);
  assert.match(menu, /itemCount: visibleItems\.length/);
  assert.match(menu, /final item = visibleItems\[index\]/);
});


test("account profile load and sync failures remain visible and retryable", async () => {
  const source = await read("lib/menu/my_account_screen.dart");
  const loadStart = source.indexOf("Future<void> _load()");
  const loadEnd = source.indexOf("Future<bool> _refresh()");
  assert.ok(loadStart >= 0 && loadEnd > loadStart, "account profile loader must exist");
  const loader = source.slice(loadStart, loadEnd);
  assert.match(loader, /profileLoadFailed = true/);
  assert.match(source, /_profileLoadFailed = profileLoadFailed/);
  assert.match(source, /account_profile_sync_pending_/);
  assert.match(source, /_setProfileSyncPending\(user, true\)/);
  assert.match(source, /profile is saved on this device, but cloud sync is pending/);
  assert.match(source, /child: const Text\('Retry'/);
  assert.doesNotMatch(loader, /catch\s*\(_\)\s*\{\s*\}/);
});

test("API diagnostics treat explicit application failure in a 2xx response as failure", async () => {
  const source = await read("lib/services/bujji_api_service.dart");
  assert.match(source, /static bool isSuccessfulApplicationResponse/);
  assert.match(source, /data\['success'\] != false/);
  assert.match(source, /applicationSuccess != false/);
  assert.match(source, /applicationSuccess: isSuccessfulApplicationResponse/);
});

test("pending account preferences survive app reload until cloud sync succeeds", async () => {
  const source = await read("lib/menu/my_account_screen.dart");
  assert.match(source, /includePreferences = false/);
  assert.match(source, /account_profile_sync_pending_\$\{user\.uid\}_dob/);
  assert.match(source, /account_profile_sync_pending_\$\{user\.uid\}_address/);
  assert.match(source, /if \(profileSyncPending\)/);
  assert.match(source, /hasPendingPreferences/);
  assert.match(source, /await _setProfileSyncPending\(user, false\)/);
});
