# BUJJI AI — Level 2 Requirement-to-Code Traceability Matrix

**Blueprint level:** 02 — Coding Gap Audit  
**Audited commit:** `1cd079e08375a97608b664bcd0fa7a423add4c3b`  
**Audit branch:** `implementation/level2-coding-gap-audit-2026-11-20`  
**Evidence type:** Static source inspection and repository test-file inspection  
**Status vocabulary:** Implemented = visible source behavior exists; Partial = some behavior exists but scope/quality/validation is incomplete; Missing = no implementation found in inspected repository; Blocked = cannot be verified without an external environment, permission or approved product decision.

> A source implementation is not proof of correct runtime behavior. Unless explicitly stated, this matrix does not claim live Firebase, Cloudflare, provider, Android-device or native-speaker verification.

## 1. User-visible feature traceability

| ID | User-facing requirement / UI entry | Source implementation | Backend / local behavior observed | Status | Gap / evidence still required | Existing test evidence |
|---|---|---|---|---|---|---|
| UI-01 | Home chat: send a text message and receive an AI reply | `lib/main.dart` — `sendMessage()`, composer and chat state | Calls shared `BujjiApiService` to Worker `/chat`; local chat history persisted in SharedPreferences | Partial | Full Flutter widget/integration journey, rapid-send race, malformed history, restore/clear and real backend behavior | `chat_message_test.dart` tests message model only; Phase 4 static contracts; Worker route tests |
| UI-02 | Chat history restore and clear | `lib/main.dart` — `_restoreMessages()`, `_persistMessages()`, `_clearLocalChatHistory()` | Local bounded persistence (up to 100 messages) | Partial | Runtime tests for corrupt/missing storage, lifecycle races, clear confirmation and persistence failures | Phase 4 source-contract tests; no dedicated history widget test |
| UI-03 | Bottom navigation (Home, Tools, History, Favorites, Explore, Menu) | `lib/main.dart` — selectedIndex and section routing | Home chat; Tools and Menu screens; History/Favorites/Explore section content is local UI/state as implemented | Partial | Verify every navigation destination, empty state, back navigation and persistence semantics; map exact action for each section | No dedicated bottom-navigation widget test |
| UI-04 | Currency converter | `lib/tools/currency_converter.dart` | External exchange-rate API plus local cached preferences | Partial | Network timeout/error, stale cache/freshness indication, invalid rate payload and offline behavior | 2 widget tests; no live provider contract evidence |
| UI-05 | Smart calculator (basic, GST, EMI, history) | `lib/tools/smart_calculator.dart` | Local calculations and local history | Implemented (source-level) | Broader numeric boundary, precision, invalid-input and accessibility checks | 7 widget tests |
| UI-06 | What Is This? photo understanding | `lib/tools/feature_tools.dart` — `_VisionPage`, `WhatIsThisScreen` | Camera/gallery selection, image size check, authenticated Worker `/vision` request, answer and Trace ID | Partial | Full device permission/cancel/upload tests, live Vision binding verification, image payload limits and privacy checks | Worker Vision tests; no Flutter device integration test |
| UI-07 | Room Designer from a room photo | `lib/tools/feature_tools.dart` — `RoomDesignerScreen` / `_VisionPage` | Reuses Vision request with room-design prompt | Partial | Same device/backend tests as UI-06; evaluate output usefulness and avoid invented room details | Worker Vision tests; no screen-level test |
| UI-08 | Brain Challenge | `lib/tools/feature_tools.dart` — `BrainChallengeScreen` | Local question/answer/score state; no Worker call observed | Partial | Validate question set, answer correctness, restart/score and accessibility; determine whether progress persistence is required | No dedicated test file found |
| UI-09 | Handwriting to Text | `lib/tools/feature_tools.dart` — `HandwritingToTextScreen` | Camera/gallery + on-device ML Kit Latin text recognition; copy result | Partial | Source explicitly says Latin/English OCR only; Telugu handwriting is unsupported. Test permission, empty/blurred images and device plugin behavior | No dedicated screen test found |
| UI-10 | Voice Studio: record, save and replay voice | `lib/tools/feature_tools.dart` — `VoiceStudioScreen` | Microphone permission, local WAV recording in app documents, local playback | Partial | Lifecycle cleanup/disposal, interrupted recording, storage growth/retention, permission denial and device matrix | No dedicated screen/device test found |
| UI-11 | Writing Assistant | `lib/main.dart` — `WritingAssistantScreen.generateWriting()` | Validates non-empty input and 3,000-character cap; calls Worker `/chat` via shared API service; supports type/language/tone/length and regenerate | Partial | Widget tests for validation/loading/error/empty response/regenerate; no end-to-end evidence; output copy/edit flow verify | No dedicated Writing Assistant widget test |
| UI-12 | Feature Assistant / content generation | `lib/main.dart` — `FeatureAssistantScreen.generateContent()` | Calls Worker `/chat` via shared API service with selected task and options | Partial | Tests per feature type, language mode, validation, retry, loading and empty/error states | No dedicated screen test |
| UI-13 | Voice & Translation | `lib/menu/menu_features.dart` — `VoiceTranslationScreen` | Speech-to-text through device speech service; typed or recognized input sent to Worker `/chat` for translation; copy result | Partial | Speech permission/service failure, language selection/meaning preservation, cancellation and network error tests; “live translation” wording should not imply continuous simultaneous translation | Phase 4 source contract checks shared transport; no widget/device test |
| UI-14 | My Learning notebook | `lib/menu/menu_features.dart` — `MyLearningScreen` | Adds, loads and deletes notes using local SharedPreferences | Partial | Test storage errors, duplicate/large inputs, lifecycle and retention; no cloud sync/progress analytics observed | No dedicated test found |
| UI-15 | App Settings | `lib/menu/menu_features.dart` — `AppSettingsScreen` | Loads/saves language, theme and notification preferences locally | Partial | Verify every setting actually affects app behavior; notification toggle requires notification behavior or must be labelled as preference-only; tests absent | No dedicated settings widget test |
| UI-16 | My Account / profile | `lib/menu/my_account_screen.dart` | Firebase Auth providers and Firestore profile save/load; DOB and profile preferences; local preferences | Partial | Credential linking, auth lifecycle, profile-write error handling, deletion/data-retention and Firestore rules integration tests | Age-band profile service tests only; no account UI/auth integration tests |
| UI-17 | Privacy & Security | `lib/menu/privacy_security.dart` | Displays privacy/security information and navigation to diagnostics | Partial | Ensure every notice matches actual provider data flow, retention and account deletion capabilities; test claims against deployed configuration | Static privacy contract test; no user-flow test |
| UI-18 | AI Diagnostics (debug-only) | `lib/menu/ai_diagnostics_screen.dart`, `lib/services/bujji_api_service.dart` | Displays locally stored bounded request metadata; refresh, clear and copy Trace ID; menu hides it outside debug mode | Partial | Widget tests, redaction tests and verification that prompts/chat/images/tokens/personal data never enter diagnostics | Phase 4 static contracts; no dedicated widget test |
| UI-19 | Feedback & Suggestions | `lib/menu/feedback_suggestions.dart` | Source inventory indicates local persistence/UI; no verified server submission path in inspected source map | Partial | Confirm whether feedback is local-only or actually submitted; label clearly; test save/reopen/delete and data handling | No dedicated test found |
| UI-20 | Help & Support | `lib/menu/help_support.dart` | Help screen and navigation to feedback | Partial | Confirm real contact/support destination and empty/error states; avoid implying live support if none exists | No dedicated test found |
| UI-21 | BUJJI Premium | `lib/menu/menu_features.dart` — `BujjiPremiumScreen` | Informational screen; no verified subscription purchase/billing backend found in inspected source map | Partial / product decision | Billing, entitlement verification, restore purchase, cancellation and server-side receipt validation are not evidenced; do not present a purchase as working until implemented | No subscription integration tests found |
| UI-22 | Share BUJJI AI | `lib/menu/menu_features.dart` — `ShareBujjiScreen` | Uses native share sheet and clipboard | Implemented (source-level) | Verify share target behavior and app-store URL/configuration; no dedicated widget test | No dedicated test found |
| UI-23 | About BUJJI AI | `lib/menu/about_bujji_ai.dart` | About screen and diagnostics entry point | Partial | Confirm displayed app/build/version metadata is dynamic and accurate; navigation test absent | No dedicated test found |
| UI-24 | Menu entries that are not yet wired to a feature | `lib/menu/menu_home.dart` — `_showComingSoon()` fallback | Displays “option added; implement details later” dialog for unmatched menu item | Implemented as placeholder | Treat as explicit placeholder, not as completed feature; each future menu action needs approved scope and implementation | No dedicated menu widget test |

## 2. Backend and platform requirement traceability

| ID | Requirement / route | Source | Observed behavior | Status | Gap / proof needed |
|---|---|---|---|---|---|
| API-01 | Worker health route | `worker.js` root route | Returns service health/version metadata | Implemented (source-level) | Live deployed version and health monitoring evidence |
| API-02 | Authenticated chat endpoint | `worker.js` `/chat` | Validates request, Firebase bearer token, rate limit, language/context and invokes model provider | Partial | Firebase revocation, live staging, quota/provider outage and end-to-end tests |
| API-03 | Authenticated Vision endpoint | `worker.js` `/vision` | Authenticated image analysis path with payload validation and Trace ID | Partial | Live binding/device upload tests, privacy and provider behavior |
| API-04 | CORS policy | `worker.js`, `wrangler.jsonc` | Explicit origin allowlist; native clients without Origin are supported | Partial | Verify actual staging/production allowed-origin values and browser preflight behavior |
| API-05 | Rate limiting | `worker.js`, Durable Object binding/migration in `wrangler.jsonc` | Worker checks a Durable Object-backed request limit and fails closed if required binding missing | Partial | Test deployed namespace/migration, concurrency, restart and 429/503 in staging |
| API-06 | Firebase token validation | `worker.js` Firebase verification helper | Verifies RS256/JWK signature and project/time/auth claims | Partial | Revocation check and live Firebase token lifecycle tests |
| API-07 | Primary model and fallback | `worker.js` provider functions | Gemini primary with Google Search tool; eligible transient failures can use OpenAI fallback | Partial | Mocked tests are not live provider/quota/freshness/grounding evidence |
| API-08 | Firestore profile access | `firestore.rules`, profile service | Authenticated user can access own `users/{uid}` document | Partial | Field schema/type/immutable-field validation and emulator/staging rules tests |
| API-09 | Shared authenticated Flutter transport | `lib/services/bujji_api_service.dart` | Firebase user/token acquisition, JSON request, timeout/response parsing and bounded diagnostics | Partial | Dedicated injectable Dart unit tests for auth/network/error/redaction boundaries |
| API-10 | OCR platform capability | `lib/tools/feature_tools.dart` | ML Kit Latin text recognition | Partial | Explicitly limited to Latin/English in UI; Telugu OCR capability is not implemented |
| API-11 | Voice capture/playback | `lib/tools/feature_tools.dart` | Native microphone recording and local playback | Partial | Permission/device/lifecycle/storage tests |
| API-12 | Exchange-rate external API | `lib/tools/currency_converter.dart` | External rate retrieval/cache | Partial | Freshness, provider outage, invalid data and offline tests |

## 3. Cross-feature error, validation, loading, empty, retry and permission audit

| Concern | Source evidence | Observed behavior | Classification |
|---|---|---|---|
| API timeout/error boundary | `lib/services/bujji_api_service.dart` | Shared HTTP timeout, response parsing and diagnostic recording exist | Partial: needs dedicated Dart tests for all error classes and redaction |
| Chat input validation | `lib/main.dart` `sendMessage()` | Empty/length checks and loading guard exist | Partial: widget/race tests absent |
| Writing/content input validation | `lib/main.dart` writing/content generators | Empty input and 3,000-character cap; duplicate submit guard; loading/finally reset; empty response check | Implemented at source level; screen tests absent |
| Vision input validation | `lib/tools/feature_tools.dart` `analyze()` | Selected-photo guard, busy guard, 5 MB byte limit, empty-answer check, error notice | Partial: device/picker/permission and live endpoint tests absent |
| OCR empty result | `lib/tools/feature_tools.dart` `convertToText()` | Empty OCR result shows a user notice | Partial: native device behavior unverified |
| Voice permission | `lib/tools/feature_tools.dart` `VoiceStudioScreen.start()` | Checks microphone permission before recording | Partial: denial/permanent denial/settings return and disposal need device tests |
| Translation readiness | `lib/menu/menu_features.dart` `_listen()` | Detects speech service initialization failure and displays notice | Partial: permission-denial and platform-specific behavior untested |
| Empty states | Menu/history/learning/tools screens | Some local empty-state text is present | Partial: inventory and widget tests needed for every destination |
| Retry behavior | API-using screens | User can generally retry by re-submitting; no common retry policy surfaced for every screen | Partial: retry/cancellation policy and transient error UX need explicit tests |
| Account/profile persistence | `lib/menu/my_account_screen.dart` | Several profile sync errors are caught and a subset are reported; some auth paths suppress profile-write errors | Gap G-04: user-visible sync status and retry needed |
| Permissions | Android manifest + image picker/speech/record plugins | Platform permissions are declared/queried in feature flows | Blocked for runtime verification: actual Android version/device permission matrix needed |

## 4. Explicit placeholders and missing/limited capability

1. **Menu fallback:** unmatched menu entries show a “details and implementation later” dialog. This is a deliberate placeholder, not a completed feature.
2. **Premium:** an informational UI is present; real subscription purchase, entitlement verification and restore flow were not evidenced in the inspected source.
3. **Handwriting OCR:** current UI explicitly states Latin/English OCR only; Telugu handwriting support is missing.
4. **Offline intelligence:** current offline path in `lib/main.dart` is limited fallback responses, not a local general-purpose language model.
5. **Live translation:** current voice translation is speech-to-text followed by an online translation request. Continuous simultaneous voice translation is not demonstrated.
6. **Support/feedback delivery:** visible screens exist; a real support ticket/feedback backend submission path was not established by the inspected source map.
7. **Multilingual QA:** language options and prompts exist; per-language native-speaker verified quality status is not implemented.
8. **World Intelligence evidence:** Google Search grounding is requested in the Gemini path; a complete source-citation/freshness/conflict/uncertainty contract is not demonstrated by current tests.

## 5. Priority coding gap list (Level 2 output)

| Priority | Gap IDs | Required next-level work |
|---|---|---|
| Critical / High security & release gates | G-01, G-02, G-03, G-09 | Revocation design, Firestore schema rules, account lifecycle policy and deployed staging proof |
| High user-impact reliability | G-04, G-05, G-06, G-08, G-10 | Profile sync visibility, shared transport tests, chat/history tests, Vision device path and live provider validation |
| High intelligence quality | G-11, G-12, G-13 | Telugu native-speaker benchmark, multilingual QA and World Intelligence retrieval/grounding evaluation |
| Medium feature completeness | G-07, G-14, UI-09, UI-15, UI-21 | Writing/feature tests, honest offline scope, Telugu OCR product decision, settings behavior and subscription design |

## 6. Interpretation and handoff

- This matrix fulfills Level 2's requirement-to-code mapping and explicit implemented / partial / missing / blocked classification.
- UI visibility is not treated as proof of a working backend or completed product flow.
- Existing tests are listed as evidence only; passing status must be read from a specific CI run, not inferred from the presence of a test file.
- The 14 G-01…G-14 items in `LEVEL2_CODING_GAP_AUDIT.md` are the prioritized engineering findings. This matrix adds the per-feature traceability layer required by the blueprint.
- Level 2 is an audit/design deliverable. The actual bug fixes and feature implementations must be made in their appropriate later implementation work after the relevant audit/design, with one logical change per PR and regression tests.
- No runtime source, Worker logic, Firebase rules/configuration, Wrangler configuration, assets, secrets or production environment were changed by this Level 2 work.
