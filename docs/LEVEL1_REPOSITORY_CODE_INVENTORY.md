# BUJJI AI — Level 1 Repository & Code Inventory

**Blueprint scope:** 01 — Repository & Code Inventory  
**Inspected ref:** `8e831e8f9c812f91374eef6eee63d9bf48c4b04e`  
**Working branch:** `implementation/level1-repository-inventory-2026-11-20`  
**Inspection type:** Git tree + source/configuration review  
**Status:** Initial inventory prepared; runtime/build verification remains a later evidence gate.

## 1. Scope and counting clarification

The recursive Git tree for the inspected ref reports **59 tree entries**, comprising **43 tracked files (blobs) and 16 directories (trees)**. The tree is not truncated. Therefore, the PDF's phrase “59 files” does not match the actual Git object breakdown at this ref. This inventory preserves both counts instead of silently treating folders as files.

- Tracked files: 43
- Directories: 16
- Total tree entries: 59
- Binary/image files: 1 (`assets/bujji_logo.png`)
- Text/source/configuration files: 42
- Git tree SHA/ref: `8e831e8f9c812f91374eef6eee63d9bf48c4b04e`

The repository default branch is `main`; the inspected Level 1 baseline is a separate approved implementation baseline. PR #5 and PR #6 were both observed as open, draft, and unmerged during this inspection. Do not assume their changes are in `main`.

## 2. Repository directory map

| Directory | Responsibility |
|---|---|
| `.github/` | GitHub automation configuration |
| `.github/workflows/` | Android, Cloudflare Worker and Phase 4 CI workflows |
| `android/` | Android platform project area |
| `android/app/` | Android application configuration |
| `android/app/src/` | Android source/resource hierarchy |
| `android/app/src/main/` | Main Android manifest and resources |
| `android/app/src/main/res/` | Android launch/theme resources |
| `android/app/src/main/res/drawable/` | Android drawable resources |
| `android/app/src/main/res/values/` | Android style/theme values |
| `assets/` | Flutter application assets |
| `docs/` | Engineering, API, architecture and deployment documents |
| `lib/` | Flutter application source |
| `lib/menu/` | Menu, account, privacy, support and diagnostics screens |
| `lib/services/` | Shared API transport and user profile services |
| `lib/tools/` | Calculator, currency and device/AI utility screens |
| `test/` | Flutter and Node.js automated tests |

## 3. Tracked file inventory (43 files)

| # | File | Purpose / ownership | Main dependencies / callers | Test evidence in repository | Initial risk / follow-up |
|---:|---|---|---|---|---|
| 1 | `.github/workflows/android-phase4-test.yml` | Phase 4 debug APK workflow; generates Android scaffolding, analyzes, tests and builds | GitHub Actions, Java 21, Flutter stable | Workflow itself; no workflow run associated with inspected commit was returned by the commit-run lookup | Medium: confirm generated platform files and actual CI run |
| 2 | `.github/workflows/android.yml` | Main-branch Android release build/signing workflow | GitHub Actions secrets, Java, Flutter, launcher icons | Build workflow; no runtime test by itself | High: release signing and generated Gradle files need controlled verification |
| 3 | `.github/workflows/cloudflare-worker.yml` | Manual production Worker deployment workflow gated to `main` and `production` environment | Wrangler action, Cloudflare token/account secrets | Workflow configuration only | High: environment reviewers/secrets and rollback need external verification |
| 4 | `.github/workflows/phase4-validation.yml` | Phase 4 Worker syntax/tests + Flutter analyze/tests + debug APK | Node 22, Flutter stable, GitHub Actions | Runs `node --test test/*.test.mjs`, `flutter analyze`, `flutter test`, debug build | Medium: validate latest branch run and staging separately |
| 5 | `README.md` | Minimal project description and deployment note | None | None | Medium: too little onboarding/setup/architecture guidance |
| 6 | `android/app/google-services.json` | Firebase Android client configuration | Firebase project/app registration | Indirectly consumed by Android/Firebase build | Medium: verify project/app match and ensure no private credential is ever added |
| 7 | `android/app/src/main/AndroidManifest.xml` | Android app permissions, package/activity and platform declarations | Flutter Android embedding and native plugins | Android build/device tests | Medium: permission and plugin behavior needs device verification |
| 8 | `android/app/src/main/res/drawable/launch_background.xml` | Native Android launch background | Android resource system | Android build/device test | Low: visual check on device |
| 9 | `android/app/src/main/res/values/styles.xml` | Android launch/theme styles | Android resource system | Android build/device test | Low: visual check on device |
| 10 | `assets/.gitkeep` | Keeps the assets directory present | Git only | Not applicable | Low: placeholder only |
| 11 | `assets/bujji_logo.png` | Flutter launcher/app logo asset | `pubspec.yaml`, flutter_launcher_icons | Build inclusion; no visual regression test found | Medium: preserve approved logo; do not change without approval |
| 12 | `docs/PHASE4_API_INVENTORY.md` | Existing API/provider/Firebase/native integration inventory | Source/configuration references | Documentation review | Medium: source snapshot; staging/live claims must be revalidated |
| 13 | `docs/PHASE4_ARCHITECTURE_AUDIT.md` | Existing architecture, privacy, auth and Phase 4 audit notes | Flutter/Worker/Firebase modules | Contract tests cover selected claims | Medium: contains time-sensitive baseline and branch-status notes |
| 14 | `docs/PHASE4_DEPLOYMENT_CHECKLIST.md` | Staging and production release gates | Firebase Console, Cloudflare, GitHub environments | Manual acceptance checklist | High: requires authorized external configuration and human approval |
| 15 | `docs/phase4-stage1-stage2-implementation.md` | Implementation notes and outstanding Phase 4 deployment/validation tasks | Profile, Telugu modules, Worker rate limiting | Related tests listed below | Medium: keep aligned with actual branch and test state |
| 16 | `firestore.rules` | Restricts each signed-in user to their own `users/{uid}` document | Firebase Authentication / Firestore | Source review; live rules simulation/publication not performed here | High: must test ownership and deployed rules before release |
| 17 | `lib/firebase_options.dart` | Flutter Firebase Android initialization options | `firebase_core`, Firebase Android project | Indirect initialization/build coverage | Medium: configuration consistency; client API config is not a service-account credential |
| 18 | `lib/main.dart` | App bootstrap, startup, chat models/state/UI, navigation and major chat flows | Flutter, Firebase Core, SharedPreferences, speech plugin, menu/tools/services | `chat_message_test.dart` covers message serialization only; Phase 4 contract checks selected source contracts | High: large 2,198-line central file; coupling and broad UI journeys need later architecture/test work |
| 19 | `lib/menu/about_bujji_ai.dart` | About screen and diagnostics entry point | Flutter, diagnostics screen | No dedicated widget test found | Low/Medium: screen navigation needs UX verification |
| 20 | `lib/menu/ai_diagnostics_screen.dart` | Device-local API diagnostics dashboard | Flutter, Clipboard, API diagnostics service | Phase 4 contract test checks visibility/source contracts; no dedicated widget test found | Medium: verify usability and local-only metadata boundary |
| 21 | `lib/menu/feedback_suggestions.dart` | Feedback/suggestions UI and local persistence | Flutter, SharedPreferences | No dedicated widget test found | Medium: persistence and privacy behavior need tests |
| 22 | `lib/menu/help_support.dart` | Help/support screen and navigation to feedback | Flutter, feedback screen | No dedicated widget test found | Low/Medium: navigation/empty states need tests |
| 23 | `lib/menu/menu_features.dart` | Menu sub-pages, premium/share/voice translation/learning flows | Flutter, platform services, SharedPreferences, Share Plus, speech, shared API service | Phase 4 contract test checks Voice Translation shared transport; no full screen tests | High: multiple user-facing flows and platform integration require end-to-end coverage |
| 24 | `lib/menu/menu_home.dart` | Menu entry list and diagnostics visibility gating | Flutter foundation/material | Phase 4 contract test checks diagnostics visibility | Medium: menu-to-screen navigation needs widget tests |
| 25 | `lib/menu/my_account_screen.dart` | Account/profile, DOB/preferred address, Firebase auth providers and profile editing | Firebase Auth, Firestore, Google Sign-In, SharedPreferences | Profile service unit tests do not cover all account UI/auth journeys | High: auth, linking, DOB and profile ownership require staging/device tests |
| 26 | `lib/menu/privacy_security.dart` | Privacy/security notices and diagnostics navigation | Flutter, diagnostics screen | Phase 4 contract test checks privacy disclosure text | Medium: claims must remain aligned with provider behavior and retention terms |
| 27 | `lib/services/bujji_api_service.dart` | Shared authenticated Worker HTTP transport, request timeout, response parsing and bounded local diagnostics | Firebase Auth, SharedPreferences, Dart IO/JSON | Worker/contract tests cover server side and source contracts; no dedicated Dart service test found | High: central network boundary; add transport tests in Level 2/3/6/7 |
| 28 | `lib/services/bujji_user_profile_service.dart` | Loads user profile context and derives coarse age band locally | Firebase Auth, Cloud Firestore | 6 unit tests for age-band boundaries/invalid dates | Medium/High: Firestore failure and preference behavior need integration tests |
| 29 | `lib/tools/currency_converter.dart` | Currency conversion UI, exchange-rate fetch/cache | Flutter, Dart IO/JSON, SharedPreferences, external exchange-rate API | 2 widget tests for screen and currency search | Medium: external API freshness, errors and offline cache need tests |
| 30 | `lib/tools/feature_tools.dart` | Utility/AI feature screens: vision/photo analysis, room design, OCR, audio/voice features | Flutter, API service, image picker, ML Kit, record, audioplayers, path_provider | Worker Vision route tests exist; no complete Flutter feature-screen tests found | High: multimodal/native permission, file and payload paths need device testing |
| 31 | `lib/tools/smart_calculator.dart` | Calculator, GST/EMI and calculation history UI | Flutter Material | 7 widget tests for core calculator flows | Low/Medium: edge cases and accessibility remain |
| 32 | `lib/tools/tools_home.dart` | Tools home navigation to calculator/currency/feature tools | Flutter Material | No dedicated widget test found | Low/Medium: verify navigation |
| 33 | `pubspec.yaml` | Flutter SDK constraints, runtime/dev dependencies and logo asset registration | Flutter/Dart packages | Dependency resolution/build workflows | High: no tracked `pubspec.lock` in inspected tree; reproducibility/dependency review needed |
| 34 | `telugu_grammar_intelligence.js` | Detailed Telugu grammar, speaker-role, honorific, dialect and silent quality guidance | Imported by `worker.js` | Worker test checks Telugu grammar prompt contract | Medium: model guidance only; native-speaker evaluation is still needed |
| 35 | `telugu_language_intelligence.js` | Telugu script, grammar, Roman Telugu and natural-language guidance | Imported by `worker.js` | Worker tests check language-selection/prompt behavior | Medium: prompt quality does not prove language quality |
| 36 | `test/bujji_user_profile_service_test.dart` | User profile age-band unit tests | Flutter Test, profile service | 6 tests | Medium: does not cover Firestore/auth integration |
| 37 | `test/chat_message_test.dart` | Chat message serialization/validation tests | Flutter Test, `main.dart` model | 3 tests | Medium: limited to model serialization |
| 38 | `test/currency_converter_test.dart` | Currency screen and picker widget tests | Flutter Test, currency screen | 2 tests | Medium: no live exchange-rate contract tests identified |
| 39 | `test/phase4_contract.test.mjs` | Static source-contract tests for history, diagnostics, Trace IDs, privacy and configuration | Node test runner, source files | 9 tests | Medium: static contract checks do not prove runtime behavior |
| 40 | `test/smart_calculator_test.dart` | Calculator widget tests | Flutter Test, calculator screen | 7 tests | Low/Medium: core paths covered; broader edge cases remain |
| 41 | `test/worker.test.mjs` | Worker route, auth, CORS, rate-limit, Gemini/fallback, Vision and trace tests | Node test runner, Worker source and test doubles | 31 tests | Medium: test doubles do not replace deployed staging/provider verification |
| 42 | `worker.js` | Cloudflare Worker API: health, chat, vision, auth, CORS, rate limits, model calls, fallback and request correlation | Cloudflare Workers, Durable Objects, Gemini, OpenAI, Workers AI, Firebase token JWK | 31 Worker tests + 9 source contract tests | High: large 1,351-line backend boundary; staged/live provider and security tests required |
| 43 | `wrangler.jsonc` | Worker entrypoint, compatibility date, AI preview/production bindings, environment vars and Durable Object migration | Wrangler, Cloudflare AI, Durable Objects | Worker config source contract tests | High: deployment bindings/migrations/secrets must be verified per environment |

## 4. Module ownership and primary data flow

### Flutter application
- **Entry point and primary UI:** `lib/main.dart`.
- **Menu/account/privacy/support/diagnostics:** `lib/menu/`.
- **Tools and device features:** `lib/tools/`.
- **Shared API transport:** `lib/services/bujji_api_service.dart`.
- **Profile context:** `lib/services/bujji_user_profile_service.dart`.
- **Firebase bootstrap:** `lib/firebase_options.dart`.

### Backend
- **Worker entry point:** `worker.js`, configured by `wrangler.jsonc`.
- **Language policy modules:** `telugu_language_intelligence.js`, `telugu_grammar_intelligence.js`.
- **Rate limiting:** `RateLimiter` Durable Object binding and migration in Wrangler configuration.
- **Firebase access policy:** `firestore.rules`.

### Main request path (source-level)
1. Flutter screen builds a request.
2. `BujjiApiService.postJson` obtains/uses a Firebase user, obtains an ID token and sends a Bearer-authenticated JSON request.
3. Cloudflare Worker validates request/CORS/auth/rate-limit controls and routes chat or vision requests.
4. Chat uses the configured Gemini primary provider and documented fallback behavior; Vision uses the Cloudflare AI binding.
5. Response metadata/Trace ID returns to Flutter; bounded metadata-only diagnostics are stored locally.

This is a source/configuration map, not evidence that each live environment or user journey has passed.

## 5. Dependency and external-service inventory

| Dependency / service | Used by | Purpose | Follow-up level |
|---|---|---|---|
| Flutter SDK / Dart | All Flutter source | Android app runtime and UI | 3, 8, 12, 14 |
| Firebase Core | `main.dart`, Firebase options | Initialize Firebase | 6, 7, 14 |
| Firebase Auth | Account, profile, API service, Worker token verification | Guest and linked identity; ID tokens | 6, 7, 14 |
| Cloud Firestore | Account/profile service | User profile document | 6, 7, 14 |
| Google Sign-In | My Account | Google credential linking/sign-in | 6, 7, 12 |
| Cloudflare Workers | `worker.js` | Backend API runtime | 5, 6, 8, 14 |
| Cloudflare Workers AI | Worker Vision route | Image query/caption model binding | 6, 8, 9, 13 |
| Durable Objects | Worker `RateLimiter` | Request rate limiting | 6, 7, 8 |
| Google Gemini API | Worker chat/provider layer | Primary chat generation and search grounding | 6, 9, 10, 11 |
| OpenAI Responses API | Worker fallback | Chat fallback after eligible Gemini failures | 6, 8, 9, 10 |
| Google Firebase Secure Token JWK | Worker auth | Verify Firebase ID token signatures | 6, 7 |
| Exchange-rate API | Currency converter | Currency rate data | 6, 8, 10 |
| speech_to_text | Main app / voice flows | Speech recognition | 8, 11, 12, 13 |
| image_picker | Feature tools | Camera/gallery input | 8, 12, 13 |
| google_mlkit_text_recognition | Feature tools | On-device OCR | 8, 11, 12, 13 |
| record / audioplayers | Feature tools | Audio capture/playback | 8, 12, 13 |
| path_provider | Feature tools | Device-local file paths | 8, 12, 13 |
| share_plus | Menu features | OS share sheet | 12 |
| shared_preferences | Main app/services/tools | Local settings/history/cache/diagnostics | 7, 8, 12 |

## 6. Test coverage inventory

The inspected tree contains **6 test files and 58 declared test cases**:

| Test file | Declared cases | Main coverage |
|---|---:|---|
| `test/worker.test.mjs` | 31 | Worker routes, validation, CORS, Firebase token checks, rate limiting, Gemini/fallback, Vision, Trace IDs |
| `test/phase4_contract.test.mjs` | 9 | Local history/diagnostics contracts, Trace ID propagation, privacy notice, auth/rate-limit/CORS config, voice transport and visibility |
| `test/bujji_user_profile_service_test.dart` | 6 | Age-band boundaries and invalid DOB handling |
| `test/chat_message_test.dart` | 3 | Chat message serialization and invalid data |
| `test/currency_converter_test.dart` | 2 | Currency screen and searchable picker |
| `test/smart_calculator_test.dart` | 7 | Calculator, division-by-zero, GST, EMI and history |

**Coverage gaps visible from the test-file inventory:** no dedicated widget/integration test files were found for the full main chat journey, My Account auth/linking, privacy/settings screens, diagnostics interactions, feedback/help navigation, voice translation, image picker/OCR/audio flows, Tools navigation or end-to-end Firebase ↔ Worker behavior on a real device.

A declared test count is not a test execution result. The commit-specific workflow-run lookup returned no associated runs for this inspected commit; therefore this document does not mark CI as passed.

## 7. Initial risks and missing repository documentation

| ID | Finding | Initial severity | Evidence / reason | Follow-up |
|---|---|---|---|---|
| L1-INV-01 | Tree count differs from the PDF's “59 files” wording | Low | 59 entries = 43 files + 16 directories | Keep explicit count and recheck at each baseline |
| L1-INV-02 | Main Flutter entry file is a large mixed-responsibility module | High | `lib/main.dart`, 2,198 lines; owns bootstrap/chat/UI/navigation and imports many feature modules | Level 2/5: map boundaries before any extraction |
| L1-INV-03 | Worker is a large combined backend module | High | `worker.js`, 1,351 lines; multiple routes/security/provider responsibilities | Level 2/5/6/7: map functions and route contracts before refactor |
| L1-INV-04 | Android platform build files are not tracked in this tree | Medium | Only manifest/resources and Firebase config are present; workflows run `flutter create --platforms=android .` | Level 3/8/14: verify generated build reproducibility |
| L1-INV-05 | No `pubspec.lock` is tracked | Medium | Not present in the complete inspected tree | Level 8/14: decide application dependency lock policy |
| L1-INV-06 | App-level widget/integration coverage is incomplete | High | 6 test files / 58 cases; major screens and native journeys have no dedicated tests | Level 2/3/6/8/12/14: create risk-based test matrix |
| L1-INV-07 | README is minimal and setup documentation is distributed | Medium | README contains only short project/deployment description | Add contributor setup, architecture links and local test instructions |
| L1-INV-08 | No dedicated architecture diagrams or module ownership map existed as a single source of truth | Medium | Existing Phase 4 docs cover selected areas, not the full repository | This inventory supplies the initial map; Level 5 expands diagrams |
| L1-INV-09 | No dedicated repository-wide `analysis_options.yaml` is tracked | Low/Medium | Not present in complete inspected tree | Level 3: decide lint policy after baseline analyzer run |
| L1-INV-10 | No dedicated CI workflow-run evidence was returned for the inspected commit | Medium | Commit workflow-run lookup returned an empty list | Re-run CI on the implementation PR and record actual run evidence |
| L1-INV-11 | External services and native plugins create environment-dependent behavior | High | Firebase, Cloudflare, Gemini/OpenAI, exchange rates, speech, OCR, camera and audio integrations | Level 6/7/8/10/12/14: staging/device validation |

### Existing documentation found
- `README.md`
- `docs/PHASE4_API_INVENTORY.md`
- `docs/PHASE4_ARCHITECTURE_AUDIT.md`
- `docs/PHASE4_DEPLOYMENT_CHECKLIST.md`
- `docs/phase4-stage1-stage2-implementation.md`

### Missing or not found in the inspected tree
- Repository-wide setup / contributor guide
- Full module ownership and dependency map (this document is the initial version)
- Current-state architecture and sequence diagrams (to be expanded in Level 5)
- Repository-wide lint/analysis configuration
- Tracked dependency lockfile
- Dedicated UI/integration test plan and test ownership guide
- Release/rollback runbook beyond the Phase 4 checklist
- Explicit data classification and retention matrix (to be expanded in Level 7)

“Not found” means absent from this inspected Git tree; it does not make claims about external systems or untracked local files.

## 8. Cross-level compatibility rules

This Level 1 inventory is deliberately descriptive and must not pre-empt later audit decisions.

1. **Level 2 — Coding gaps:** map each product requirement to existing files and classify implemented / partial / missing / blocked before coding.
2. **Level 3 — Bugs and warnings:** run analyzer, Node tests, Flutter tests and clean builds; record reproducible evidence before fixes.
3. **Level 4 — Duplicate/unused code:** do not remove or consolidate a file based only on its name or apparent lack of references.
4. **Level 5 — Architecture:** use the current ownership map to plan modular boundaries without breaking the current Flutter → Worker → provider contracts.
5. **Level 6 — API/Firebase:** preserve request/response contracts, auth requirements, Firestore ownership and environment separation.
6. **Level 7 — Security/privacy:** never expose prompts, chat history, image bytes, access tokens, DOB, phone/email or Firebase UID in diagnostics.
7. **Level 8 — Performance/reliability:** retain low-memory Android and slow-network constraints when changing services or UI.
8. **Level 9 — Reasoning:** keep orchestration/provider boundaries compatible with future reasoning/evaluation layers.
9. **Level 10 — Search/verification:** preserve source provenance, freshness and uncertainty requirements in future retrieval architecture.
10. **Level 11 — Multilingual quality:** retain Telugu language modules and their native-speaker validation requirement; do not mark languages verified from prompt presence alone.
11. **Level 12 — UX:** preserve approved app branding and test user journeys before changing screens.
12. **Level 13 — Future architecture:** keep speech, translation, multimodal, offline and controlled self-evolution as planned modules, not unreviewed changes in Level 1.
13. **Level 14 — Release readiness:** require test evidence, staging verification, unresolved-risk register and explicit release approval.

## 9. Level 1 completion criteria

- [x] Recursive repository tree captured and not truncated.
- [x] Directory count and tracked-file count recorded separately.
- [x] All 43 tracked file paths listed.
- [x] Initial module ownership, dependency and test maps prepared.
- [x] Initial risk and missing-documentation register prepared.
- [x] Existing Phase 4 documents referenced rather than overwritten.
- [ ] Full line-by-line review of every source module and call-site graph.
- [ ] Automated baseline analyzer/test/build run on this exact branch.
- [ ] Review of findings against Levels 2–14 before any runtime-code refactor.
- [ ] Reviewer approval and branch/PR validation.

**Level 1 status: Inventory documentation drafted; not yet fully verified or complete.** Do not mark Level 1 complete until the remaining unchecked evidence and review items pass.

## 10. Change boundary

This Level 1 change adds documentation only. It does not modify Flutter runtime code, Worker logic, Firebase rules/configuration, secrets, production bindings, branding assets, user data or deployment behavior. No production deployment or merge is authorized by this document.
