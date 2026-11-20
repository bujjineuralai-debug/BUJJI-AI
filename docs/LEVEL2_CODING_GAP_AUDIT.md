# BUJJI AI — Level 2 Coding Gap Audit

**Blueprint level:** 02 — Coding Gap Audit  
**Audit title:** Feature completion / incompleteness and implementation gaps  
**Audited source ref:** `1cd079e08375a97608b664bcd0fa7a423add4c3b`  
**Parent branch:** `implementation/level1-repository-inventory-2026-11-20`  
**Level 2 branch:** `implementation/level2-coding-gap-audit-2026-11-20`  
**Inspection type:** Read-only source, test, configuration and existing-document audit  
**Status:** Findings recorded; no runtime implementation changes made.

## 1. Protection boundary and audit method

This Level 2 branch was created from the verified Level 1 branch head. Level 1's branch, commit and PR were not edited. This report is an additive artifact on a separate branch.

The audit compared:
- Flutter entry points, services, account/menu screens and tools.
- Cloudflare Worker routes, Firebase token validation, rate limiting and model-provider calls.
- Firestore and Wrangler configuration.
- Existing Flutter and Node test sources.
- Existing Phase 4 API, architecture and deployment documents.

A source-level implementation or mock test is not treated as proof of live Firebase, Cloudflare, provider, Android-device or native-speaker validation. Findings are classified by impact and by the evidence still required.

## 2. Executive result

The repository already contains working foundations for authenticated API transport, chat/history persistence, diagnostics, Firebase profile handling, Worker authentication, rate limiting, Gemini/OpenAI fallback, Vision, Telugu prompt guidance and search grounding.

The main gaps are not that these foundations are entirely absent. They are that some security/lifecycle controls are incomplete, important user journeys lack runtime integration coverage, and several product-quality goals require real-world validation or additional systems.

**14 current coding/verification gaps** are recorded below. This is a fresh evidence-based re-audit of the current Level 1 branch; it does not claim that every finding is word-for-word identical to any earlier draft list.

## 3. Findings

| ID | Priority | Gap | Evidence observed | Required closure evidence / dependency |
|---|---|---|---|---|
| G-01 | High / release gate | Firebase ID-token revocation is not checked. The Worker validates RS256 signature, issuer, audience and time claims, but does not consult a trusted revocation-time source. | `worker.js` token verification path; `docs/PHASE4_API_INVENTORY.md` and `docs/PHASE4_ARCHITECTURE_AUDIT.md` explicitly record revocation as outstanding. | Design a least-privilege server-side revocation check (Firebase Admin or equivalent trusted source), threat-model its availability/cache behavior, and test revoked, valid, expired and unavailable-source cases in staging. Never embed service-account credentials in Flutter or source control. |
| G-02 | High | Firestore rules enforce per-user document ownership but do not validate an allowed field set, field types, lengths or immutable fields. | `firestore.rules` allows read/create/update/delete when `request.auth.uid == userId`; no field/schema predicates are present. | Define the profile schema and permitted mutations, add rules-level validation, and test owner/non-owner, unexpected fields, type violations and deletion behavior in Firebase Emulator/staging. Coordinate with profile fields already in use. |
| G-03 | High | Account lifecycle is not covered end-to-end, and there is no in-app account deletion flow. Phone OTP, Google, email/password, anonymous-to-linked credential flows and profile persistence span multiple UI/provider states. | `lib/menu/my_account_screen.dart` contains these flows; `docs/PHASE4_ARCHITECTURE_AUDIT.md` privacy notice states there is no in-app account deletion flow. Existing profile unit tests cover age-band calculation only. | Add integration tests for sign-up, login, credential linking, duplicate/invalid credentials, verification and profile ownership. Define account deletion/export/data-retention behavior before implementing a user-facing deletion flow. Requires Firebase test project and policy decision. |
| G-04 | Medium / reliability | Some account flows suppress profile-write errors, so authentication can appear successful while profile persistence silently fails. | In `lib/menu/my_account_screen.dart`, OTP/email paths wrap `_saveCloudProfile` in empty `catch (_)` blocks; profile loading also intentionally degrades silently in `BujjiUserProfileService`. | Distinguish optional personalization failure from required account persistence. Surface a safe retry/status for profile writes and test Firestore offline/permission-denied behavior. Do not block ordinary chat when optional profile context is unavailable. |
| G-05 | Medium | Shared Dart API transport has no dedicated unit-test file. Auth/session creation, Bearer token handling, timeout behavior, malformed responses, diagnostic redaction and HTTP error handling are central to all online features. | `lib/services/bujji_api_service.dart` implements the transport; current tests include Worker tests and static source contracts but no dedicated Dart API-service test. | Introduce an injectable HTTP/auth boundary and unit-test success, 4xx/5xx, timeout, invalid JSON, missing token, diagnostics bounds and redaction. Preserve one shared transport for all Worker callers. |
| G-06 | Medium | Chat/history persistence has static contract coverage but lacks dedicated runtime widget/integration coverage for restore, clear, malformed stored data and lifecycle races. | `lib/main.dart` stores/restores up to 100 messages; `test/phase4_contract.test.mjs` checks source patterns rather than exercising Flutter runtime behavior. | Add Flutter tests with controlled SharedPreferences for startup restore, clear, malformed entries, rapid sends, app lifecycle and persistence failures. Keep history local and bounded unless a separately approved sync design is introduced. |
| G-07 | Medium | Writing Assistant, Feature Assistant and Voice Translation use the shared Worker service, but their screen-level success/error/regeneration/language journeys lack dedicated widget/integration tests. | `lib/main.dart` writing/content flows and `lib/menu/menu_features.dart` translation flow call `BujjiApiService.postJson`; existing test set has no dedicated screen test for these journeys. | Add tests for input validation, loading/duplicate-submit prevention, empty/error replies, selected language/tone, regeneration and safe UI state after navigation. Keep transport centralized. |
| G-08 | Medium / device validation | Vision has Worker request/payload tests, but the full Flutter camera/gallery → file encoding → authenticated upload → result/error path is not covered on real Android devices. | `lib/tools/feature_tools.dart` owns image selection and API submission; `worker.js` Vision route is covered by mocked Worker tests. | Add Flutter widget/service tests with image-picker fakes, payload-size/type cases and device tests for camera/gallery permissions, large images, cancellation and network failure. Do not log or persist image bytes. |
| G-09 | High / release gate | Staging integration evidence for Firebase, Cloudflare bindings and the deployed Durable Object is still outstanding. The Worker has isolated unit tests, including a RateLimiter class test, but these do not prove the actual Cloudflare namespace, migration and environment are configured correctly. | `test/worker.test.mjs` tests a simulated namespace/storage path; `docs/PHASE4_DEPLOYMENT_CHECKLIST.md` lists real staging checks not yet evidenced in this audit. | Run a non-production staging suite covering valid/invalid Firebase tokens, auth-required routes, actual Durable Object binding/migration, rate-limit 429/503 fail-closed behavior, CORS and restart behavior. No production deployment is implied. |
| G-10 | High / release gate | AI-provider tests use mocked network responses; real Gemini, Google Search grounding and OpenAI fallback behavior under the configured staging project/quota has not been proven by repository tests. | `test/worker.test.mjs` stubs `globalThis.fetch` for Gemini/OpenAI; Worker source enables Gemini `google_search` and an OpenAI fallback path. | Test provider success, quota/rate limits, transient and non-retryable errors, timeout, malformed provider payloads, grounding metadata and both-provider outage in staging. Verify current provider terms and never expose keys/prompts in logs. |
| G-11 | High / product quality | Telugu prompt guidance and source-contract tests exist, but there is no demonstrated native-speaker benchmark/acceptance process for naturalness, dialect fidelity, grammar and meaning preservation. | `telugu_language_intelligence.js`, `telugu_grammar_intelligence.js` and Worker prompt tests provide model guidance; current tests assert prompt/source behavior, not Telugu answer quality. | Establish reviewed benchmark questions and native-speaker evaluation across Telangana, Uttarandhra, Godavari, Rayalaseema, Hyderabad and everyday speech. Track meaning preservation, fluency, dialect and correction behavior separately. |
| G-12 | Medium / roadmap | A systematic multilingual quality verification framework is not present in the inspected source/test inventory. | Current language prompt modules and tests are Telugu-focused; no per-language benchmark/verified-status/evaluation module was found in the repository tree. | Add the planned multilingual QA process: native-speaker review, independent AI cross-check, back-translation/meaning checks, verified benchmark answers, user feedback and separate per-language quality status. Do not mark a language verified before review. |
| G-13 | High / product quality | Search grounding is enabled in the Gemini request, but there is no demonstrated end-to-end quality contract for source attribution, freshness, source reliability, uncertainty and answer verification across broad World Intelligence questions. | `worker.js` requests Gemini `google_search`; current tests verify mocked model behavior and do not validate source quality or freshness. | Define the World Intelligence retrieval/answer contract, including when to search, source display/attribution, freshness, conflict handling, uncertainty and safe no-result behavior. Add evaluation cases before broadening capabilities. |
| G-14 | Medium / product scope | The current Offline Mode is limited canned local replies, not a local language model or broad offline assistant. | `lib/main.dart` `getOfflineReply` handles greetings/help and otherwise returns a fixed connectivity message. | Keep the UI honest about limited offline capability. A true offline model is a separate later design requiring device RAM/storage, model licensing, download/update, privacy, latency and battery evaluation; do not silently label canned replies as full offline AI. |

## 4. Cross-cutting engineering risks (not counted as additional feature gaps)

1. **Large central modules:** `lib/main.dart` is approximately 2,198 lines and `worker.js` approximately 1,351 lines. This increases change coupling and regression risk. Modularization should be planned before adding major new flows, not performed as an uncontrolled rewrite.
2. **Dependency reproducibility:** no tracked `pubspec.lock` was present in the inspected tree. Decide and document the application lockfile policy, then validate clean dependency resolution in CI.
3. **Test-type distinction:** source-contract tests, unit tests, simulated Durable Object tests, staging tests, Android-device tests and native-speaker evaluation provide different evidence. A green CI run proves the configured automated checks passed; it does not replace the other evidence types.
4. **External configuration:** Firebase providers/rules, Cloudflare secrets/bindings/migrations, CORS origins, provider quotas and GitHub production-environment reviewers must be verified in their actual environments. They cannot be inferred from checked-in source alone.

## 5. Recommended closure order

1. Resolve the security/release design items first: G-01 token revocation, G-02 Firestore schema rules, G-03 account lifecycle/deletion policy, G-04 profile-write reliability.
2. Strengthen shared foundations: G-05 API transport tests, G-06 chat/history runtime tests, G-07 writing/feature/translation tests, G-08 Vision device path.
3. Validate the deployed integration boundary: G-09 staging/Firebase/Durable Objects and G-10 real provider behavior.
4. Build quality systems before claiming intelligence quality: G-11 Telugu native-speaker QA, G-12 multilingual QA, G-13 World Intelligence grounding evaluation.
5. Keep G-14 offline capability accurately scoped and plan a separate device-feasibility design.

This is an ordering recommendation, not authorization to implement all gaps in one batch. Each later implementation must be isolated, reviewed against dependent levels, and tested before moving forward.

## 6. Level 1 compatibility and preservation check

- Level 1 inventory file is inherited unchanged from parent commit `1cd079e08375a97608b664bcd0fa7a423add4c3b`.
- Level 1 workflow trigger and inventory content are not edited by this Level 2 commit.
- No Flutter runtime source, Worker runtime source, Firebase rules/config, Wrangler config, assets, secrets or production environment were changed.
- PR #7 remains a separate Draft PR; this Level 2 branch is based on its current head, not a modification to its branch.
- The Level 1 CI Run #123 was green before this Level 2 documentation-only branch was created.
- This report does not close Level 1's remaining source-review and cross-level-review gates, and does not authorize a merge or deployment.

## 7. Level 2 completion checklist

- [x] Inspect Level 1 inventory and existing Phase 4 architecture/API/deployment documents.
- [x] Inspect Flutter shared transport, profile service, account flows, chat/history, writing/content, translation and Vision entry points.
- [x] Inspect Worker Firebase token verification, rate limiting, provider routing and Vision route.
- [x] Inspect Firestore/Wrangler configuration and current test coverage.
- [x] Record 14 evidence-backed coding/verification gaps with priorities and closure evidence.
- [x] Record cross-cutting risks and safe closure order.
- [x] Keep Level 1 source branch unchanged.
- [ ] Independent review of findings and approval before any gap implementation.
- [ ] Plan the consolidated architecture/design stage before coding across multiple gaps.

**Level 2 audit report prepared. Runtime coding intentionally not performed in this level.**
