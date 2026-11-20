# BUJJI AI — Level 3 Error, Bug & Warning Audit

**Blueprint level:** 03 — Error, Bug & Warning Audit  
**Audit branch:** `implementation/level3-error-bug-warning-audit-2026-11-20`  
**Parent Level 2 commit:** `bdeb611c8d6d15d1e4bc5b2bfd40db24e1c3d051`  
**CI trigger commit:** `6d8ef300467218f92e3f6d89ae8abf9fdbf653f9`  
**Workflow:** BUJJI AI Phase 4 Validation — Run #124 / ID `44680914107`  
**Inspection boundary:** Source review + automated CI. No production/staging credentials, live provider calls, Firebase emulator, physical Android device or user data were used.

## 1. Audit method and evidence labels

This report separates evidence so a passing CI run is not overstated.

- **CI-reproduced:** The named automated check ran and produced the recorded result.
- **Source-confirmed path:** The code contains a deterministic error-handling path, but it was not forced against a live Firebase/provider/device in this audit.
- **Runtime unverified:** Requires staging credentials, a Firebase emulator, live provider, physical device or controlled fault injection.
- **Not a bug:** A deliberate fallback or limitation is documented as a risk/behavior, not mislabeled as a defect.

The PDF requires Flutter analyze, unit/widget/integration tests, Worker tests, clean build, and each bug to have reproducible steps, expected/actual behavior, evidence, severity, root cause, fix proposal and regression test. This report records those fields and explicitly marks the remaining runtime gates.

## 2. Automated validation results

### CI Run #124

| Check | Result | Evidence / boundary |
|---|---|---|
| Worker module syntax | Passed | `node --input-type=module --check < worker.js` |
| Node automated suite | **50 passed, 0 failed** | `node --test test/*.test.mjs`; includes Worker route/security/provider mocks and Phase 4 source-contract tests |
| Flutter dependency install | Passed | `flutter pub get` |
| Flutter analyze | Passed | `flutter analyze --no-fatal-infos`; warning/error exit gate passed; info-level diagnostics are non-fatal by configuration |
| Flutter tests | Passed | `flutter test` |
| Debug APK clean build | Pending at report creation | Build step was still running; do not treat it as passed until run conclusion confirms success |
| Live Firebase / Cloudflare / Gemini / OpenAI integration | Not run | Test doubles and CI build do not prove live external-service behavior |
| Physical-device permission / lifecycle tests | Not run | Requires device matrix and controlled permission/network conditions |

Run URL: https://github.com/bujjineuralai-debug/BUJJI-AI/actions/runs/44680914107

### Interpretation

- The Node suite passed its 50 executed test cases. It covers request validation, CORS, Firebase JWT verification with generated test keys, Durable Object rate-limit behavior via test doubles, language selection, Vision mocks, Trace ID/audit behavior and provider fallback mocks.
- Flutter analyze and the existing Flutter test suite completed successfully in CI. The suite does not provide full screen-by-screen or physical-device integration coverage.
- The Debug APK build was still in progress when this report was authored. A final green CI conclusion is a required completion gate.
- Mocked Gemini/OpenAI/Firebase/Cloudflare interactions are not live service tests.

## 3. Reproducible bug register

### BUG-L3-001 — Account authentication can report success while Firestore profile sync silently fails

| Field | Finding |
|---|---|
| Severity | Medium (P2) — profile/data consistency and misleading success state; not an authentication bypass |
| Status | Source-confirmed failure path; live reproduction pending |
| Affected flows | Phone OTP sign-in/sign-up; Email sign-up/sign-in; Google sign-in refresh path |
| Evidence | `lib/menu/my_account_screen.dart`: phone profile save is swallowed near line 482; email sign-up and sign-in profile saves are swallowed near lines 574 and 592; profile refresh swallows failures around lines 124–139; Google flow can show a sync warning and then show a final generic success notice around lines 251–255 |
| Root cause | Broad `catch (_)` blocks discard Firestore write/read errors and do not persist a visible “profile sync pending/failed” state. In the Google path, a later success notice can replace the earlier sync warning. |

**Reproduction procedure (controlled Firebase emulator/staging required):**
1. Configure Firebase Authentication to allow the chosen sign-in provider.
2. Configure Firestore rules or emulator fault injection to deny/fail writes to `users/{uid}` while authentication itself remains available.
3. Complete phone OTP or email sign-in/sign-up; repeat for Google if configured.
4. Reopen My Account and inspect the Firestore user document and displayed profile fields.

**Expected:** Authentication may succeed, but BUJJI clearly reports profile sync failure, preserves the unsynced fields safely, and offers a retry/status path.  
**Actual source path:** The profile write exception is ignored in phone/email paths; navigation can report success while the profile document is absent or stale. Google can end with a generic “sign-in successful” notice after the sync warning.  
**Fix proposal:** Replace silent catches with typed error handling; separate auth success from profile-sync status; retain a safe local pending-sync state; add an explicit retry; never log tokens or private profile data.  
**Regression tests:** Unit/widget tests with an injectable profile repository that fails reads/writes; assert auth result and profile-sync state are distinct; assert user sees a clear retry message. Add emulator rules-denial integration test.

### BUG-L3-002 — Account profile load failure silently degrades to incomplete profile data

| Field | Finding |
|---|---|
| Severity | Low/Medium (P3) |
| Status | Source-confirmed path; user-visible runtime impact not yet reproduced |
| Evidence | `lib/menu/my_account_screen.dart`, around lines 100–112: Firestore profile read and field parsing are inside `catch (_)`; the screen then continues with Firebase Auth defaults and clears its loading state |
| Reproduction | Sign in successfully, make the Firestore `users/{uid}` read fail (permission denied/network fault), then open My Account |
| Expected | Clearly indicate that cloud profile data could not be loaded and offer retry while preserving safe local/auth values |
| Actual source path | The exception is ignored; the UI may show an incomplete profile without explaining that the cloud read failed |
| Root cause | Profile read failure is treated the same as “no profile fields available” |
| Fix proposal | Distinguish document-not-found from permission/network errors; show a non-blocking sync state and retry |
| Regression test | Fake repository tests for not-found, permission-denied, timeout and successful profile load |

### BUG-L3-003 — Diagnostics outcome is based on HTTP status, not application-level success

| Field | Finding |
|---|---|
| Severity | Low (P3, observability accuracy) |
| Status | Defensive contract gap; current Worker error routes generally use non-2xx status, so an affected live route has not been demonstrated |
| Evidence | `lib/services/bujji_api_service.dart`, around lines 48–65 and 150–160: diagnostic outcome is derived from HTTP status and transport error type; a valid JSON HTTP 2xx response with `success: false` would be recorded as success |
| Reproduction | Unit-test the API transport with a valid HTTP 200 JSON response containing `{"success":false,"error":"..." }` |
| Expected | Diagnostics classify application-level failure as failure |
| Actual | Transport records success because the HTTP status is 2xx; the calling screen may subsequently detect `success != true` |
| Root cause | Transport diagnostics do not inspect the response contract's application-level success field |
| Fix proposal | Define a documented response outcome contract and record application-level failure separately from transport success; avoid changing callers' response handling |
| Regression test | Inject 2xx success, 2xx application failure, 4xx, 5xx, invalid JSON and timeout responses; assert the diagnostic outcome for each |

## 4. Warning and reliability register

### WARN-L3-001 — Node `punycode` module deprecation warning

- **Severity:** Low / toolchain warning.
- **Evidence:** CI Worker job emitted Node `[DEP0040]` twice: “The punycode module is deprecated. Please use a userland alternative instead.”
- **Impact:** No test failure; source package responsible was not identified by the emitted warning.
- **Next step:** When needed, rerun with `node --trace-deprecation` in CI or update the dependency/action that imports the deprecated module after identifying its owner. Do not change application logic based on an untraced warning.

### WARN-L3-002 — GitHub Actions Node 20 runtime deprecation

- **Severity:** Low / CI maintenance.
- **Evidence:** CI log warns `actions/checkout@v4` and `actions/setup-node@v4` target Node 20 and are being forced to Node 24 by the runner.
- **Impact:** Current run succeeds; future action-runtime compatibility may require maintenance.
- **Next step:** Review current supported major versions of the GitHub Actions and upgrade in a dedicated CI maintenance change, then rerun all workflows. Do not mix this with app runtime fixes.

### WARN-L3-003 — Gemini Google Search grounding may be unavailable for a configured API project

- **Severity:** Medium / intelligence-quality degradation, configuration-dependent.
- **Evidence:** `worker.js` logs a warning and retries the same Gemini request without Google Search grounding when a 400/403 response matches the search-tool-unavailable pattern (around lines 213–220).
- **Impact:** Chat can still return an answer, but current-information verification/grounding is reduced for that request.
- **Classification:** Deliberate graceful fallback, not a proven crash/bug.
- **Next step:** Validate the configured Gemini project and grounding entitlement in staging; expose provenance/freshness limitations in the future search-verification layer.

### WARN-L3-004 — External/native runtime paths remain unverified

- Firebase token revocation and live Firestore rules behavior
- Durable Object binding/migration behavior in deployed Cloudflare environments
- Real Gemini Search grounding, provider quota/rate-limit behavior and OpenAI fallback
- Android camera/gallery, microphone, speech service, OCR and audio lifecycle under permission denial, process recreation and low-storage conditions
- Slow network, offline transitions, request cancellation and app background/resume

These are explicit verification gaps, not asserted defects. The existing CI mocks cannot reproduce these external conditions.

## 5. Existing safeguards observed

- Flutter shared API transport has connection/request/response timeouts and closes its `HttpClient` in `finally`.
- Worker request-body reader enforces byte limits and cancels the stream when the maximum is exceeded.
- Worker rate limiting fails closed when required configuration/bindings are missing and returns 429/503 paths.
- Worker Firebase token verification checks signature and token/project/time claims; token revocation remains a separate Level 6/7 gap.
- Worker tests cover malformed JSON, unsupported content type, oversized body, missing/invalid auth, rate-limit denial, Vision validation and provider fallback.
- Currency converter applies request timeouts and uses local cached rates after fetch failure; stale-data labeling and age policy remain a separate reliability check.
- Voice Studio disposes its recorder/player, but file retention/cleanup and device lifecycle behavior need a separate test.

## 6. Test coverage and known blind spots

| Area | Automated evidence | Remaining gap |
|---|---|---|
| Worker request/security/provider paths | Node suite: 50 passed | Live deployed bindings and real provider behavior |
| Flutter analyzer | CI passed with `--no-fatal-infos` | Info-level diagnostics are non-fatal; no claim of zero infos without log inspection |
| Flutter unit/widget suite | CI passed | Major app journeys lack dedicated widget/integration tests |
| API transport | Source contracts only | No injectable Dart transport unit suite for all failure modes |
| Account/profile | Profile age-band unit tests exist | No complete auth-provider + Firestore emulator journey |
| Vision/OCR/audio/speech | Worker Vision mocks; no full Flutter device test | Physical-device permission, lifecycle and network matrix |
| Performance/race/cancellation | No load/device benchmark in this run | Stress and controlled-fault tests remain |

## 7. Prioritized fix and verification proposal

1. **P2 — BUG-L3-001:** Make profile-sync failures visible and retryable without conflating them with Firebase authentication success.
2. **P3 — BUG-L3-002:** Distinguish missing profile from failed profile read and provide retry/status.
3. **P3 — BUG-L3-003:** Align diagnostics with the API application-level response contract.
4. **CI maintenance — WARN-L3-001/002:** Identify the deprecated Node dependency and review supported action runtimes.
5. **Intelligence verification — WARN-L3-003:** Confirm Google Search grounding configuration and define a user-visible source/freshness contract.
6. **Staging/device gates — WARN-L3-004:** Add controlled Firebase/Cloudflare/provider/device tests before release claims.

No production configuration, secrets, Firebase rules, Worker logic, user data or app branding were changed during this audit. The only workflow change is an explicit push trigger for this Level 3 audit branch so the existing validation workflow can run.

## 8. Level 3 completion gates

- [x] Blueprint Level 3 scope checked against the PDF.
- [x] Worker syntax and automated Node tests executed in CI.
- [x] Flutter dependency installation completed.
- [x] Flutter analyze completed successfully under the workflow's `--no-fatal-infos` policy.
- [x] Flutter tests completed successfully.
- [ ] Debug APK build completes successfully and CI Run #124 concludes green.
- [x] Findings recorded with severity, evidence, reproduction procedure or explicit runtime blocker, root cause and fix/regression-test proposal.
- [ ] Controlled Firebase emulator/staging reproduction for profile-sync findings.
- [ ] Live provider and physical-device fault-injection tests.
- [ ] Reviewer review and approval.

**Level 3 status:** Audit findings and CI evidence are documented; final clean-build and external runtime verification gates must pass before Level 3 can be called fully complete. This PR remains Draft and unmerged.