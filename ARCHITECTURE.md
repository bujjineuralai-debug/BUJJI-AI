# BUJJI AI Architecture

## Scope

This document describes the current application and backend boundaries. It records the architecture refactor on the audit branch and the remaining limitations. It does not certify production security, provider availability, or live-service behaviour.

## Runtime overview

```text
Flutter Android application
  ├─ App bootstrap and startup
  ├─ Chat / assistant / tools / menu presentation
  ├─ Core API client
  │    └─ HTTPS JSON requests
  └─ Firebase client
       ├─ Firebase Authentication
       └─ Cloud Firestore profile documents

                 HTTPS
                   |
                   v
Cloudflare Worker entrypoint (worker.js)
  ├─ Shared HTTP/CORS utilities
  ├─ Chat route
  │    ├─ Request validation and history cleaning
  │    ├─ Language detection / reply instruction
  │    └─ AI provider orchestration
  │         ├─ Gemini primary
  │         └─ Cloudflare Workers AI fallback
  └─ Vision route
       └─ Cloudflare Workers AI vision model
```

## Flutter structure

- `lib/main.dart`: Firebase initialization and application bootstrap only.
- `lib/app/bujji_app.dart`: MaterialApp, theme and root screen.
- `lib/app/startup_screen.dart`: startup / splash transition.
- `lib/core/config/app_config.dart`: shared public service endpoint configuration.
- `lib/core/network/bujji_api_client.dart`: one HTTP boundary for BUJJI Worker JSON requests, timeouts, response decoding and chat contract handling.
- `lib/core/theme/bujji_background_painter.dart`: shared neural background painter.
- `lib/features/chat/models/chat_message.dart`: chat message model and serialization.
- `lib/features/chat/presentation/bujji_home_screen.dart`: chat screen, current-session state, navigation shell and voice input.
- `lib/features/assistants/presentation/assistant_screens.dart`: writing and feature-assistant screens.
- `lib/menu/` and `lib/tools/`: existing menu and tool modules.

### Flutter request flow

Chat, writing, feature-assistant and translation screens call `BujjiApiClient.sendChat`. Vision calls `BujjiApiClient.postJson('/vision', ...)`. The endpoint is configured once in `AppConfig`. The client accepts an optional base URL so tests can use a local HTTP server without contacting production.

The currency converter still has its own external exchange-rate endpoint and local cache. It is a separate integration, not a BUJJI Worker request.

## Cloudflare Worker structure

- `worker.js`: thin dispatcher for CORS preflight, health, chat, vision and unknown routes.
- `worker/core/http.js`: response headers, JSON response helper, request limits and history cleaning.
- `worker/routes/chat.js`: chat request validation and response orchestration.
- `worker/routes/vision.js`: image request validation and vision processing.
- `worker/services/language.js`: language and Telugu dialect detection plus reply-language instruction.
- `worker/services/chat_provider.js`: existing Gemini primary / Workers AI fallback implementation.

The Worker entrypoint remains `worker.js`, as configured in `wrangler.jsonc`. Provider behaviour and model selection were intentionally not redesigned as part of this architecture refactor.

## Data ownership and persistence

- Active chat messages are held in the chat screen's in-memory state. They are not yet persisted as a conversation history store.
- The History and Favorites tabs currently show placeholder/empty states; a durable conversation/favorites repository is not implemented.
- Account profile operations use Firebase Authentication and Cloud Firestore.
- Firestore rules restrict each signed-in user to their own `users/{userId}` document.
- App preferences, learning notes, currency-rate cache and feedback data use local preferences in their existing modules.

## Validation

- Flutter unit/widget tests live in `test/`.
- Worker route tests live in `worker/tests/` and use Node's built-in test runner.
- `npm run check:worker` checks Worker module syntax.
- `npm run test:worker` runs Worker route/history tests.
- GitHub Actions workflow `.github/workflows/architecture-validation.yml` runs Worker checks and Flutter analysis/tests on pushes and pull requests.

## Known architecture limitations (not silently treated as fixed)

1. The chat presentation class still owns navigation-shell state and active conversation state. A dedicated state-management/repository layer can be introduced later without changing current UI behaviour.
2. History and Favorites persistence is not implemented.
3. Several individual menu/tool screens still own their local persistence or external service calls. Those should receive feature-specific repositories when those features are audited.
4. Firebase Authentication and Firestore profile storage are client-side integrations. The Worker currently exposes chat/vision routes without an established Firebase ID-token verification boundary. This is a separate security/authentication task and was not changed here.
5. CORS currently allows all origins. Restricting origins requires a deliberate deployment-environment policy and is not changed in this architecture-only refactor.
6. This refactor does not change Gemini/Fallback model configuration, prompts, retry policy, vision model behaviour, or production deployment.

## Deployment boundary

The audit work is isolated on `improvements/audit-hardening-2026-11-13`. The existing production workflows target `main`; this refactor does not merge to `main`, deploy the Worker, or publish an Android build.
