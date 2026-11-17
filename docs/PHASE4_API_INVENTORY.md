# BUJJI AI Phase 4 — API & Integration Inventory

**Audit date:** 2026-11-16  
**Repository branch:** `phase4/stage1-stage2-implementation-2026-11-16`  
**Purpose:** Enumerate application network APIs, Worker routes, model providers, Firebase services and native device integrations so that an API caller is not silently omitted.

This is a source/configuration inventory. A listed integration is not proof that the live production or staging environment has passed a runtime test.

## 1. Flutter → BUJJI Worker routes

| Route | Caller / feature | Method | Authentication / trace |
|---|---|---|---|
| `/chat` | Main chat (`lib/main.dart`) | POST | `BujjiApiService.postJson`; Firebase Bearer token; response `requestId` |
| `/chat` | Writing Assistant (`lib/main.dart`) | POST | Shared authenticated service |
| `/chat` | Feature Assistant (`lib/main.dart`) | POST | Shared authenticated service |
| `/chat` | Voice Translation (`lib/menu/menu_features.dart`) | POST | Shared authenticated service; corrected on this branch to remove an unauthenticated direct HTTP call |
| `/vision` | Photo / room analysis (`lib/tools/feature_tools.dart`) | POST | Shared authenticated service; response `requestId` |
| `/` | Worker health response (`worker.js`) | GET | Health/status route; no Flutter call site identified in this audit |

The shared transport obtains or creates a Firebase session, obtains an ID token, sends `Authorization: Bearer <token>`, applies request timeouts, and records a bounded metadata-only local diagnostic entry. Chat and Vision display/log their Trace ID; Writing, Feature and Voice Translation requests are still recorded by the shared service.

## 2. Worker → model/provider APIs

| Provider | Model / endpoint | Purpose | Credential / binding |
|---|---|---|---|
| Google Gemini API | `v1beta/models/gemini-3.8-flash:generateContent` | Primary chat, writing, feature and translation generation | `GEMINI_API_KEY` Cloudflare Worker Secret |
| OpenAI API | `v1/responses` with `gpt-6-luna` | Chat fallback only after transient Gemini/network failures | `OPENAI_API_KEY` Cloudflare Worker Secret |
| Google Search grounding | Gemini `google_search` tool | Search-grounded responses and source URLs when available | Uses the Gemini API key; tool is part of the Gemini request |
| Cloudflare Workers AI | `@cf/moondream/moondream3.1-9B-A2B` | Vision image query, with caption fallback if query answer is empty | Worker `AI` binding |

Gemini 3.8 Flash is listed as a stable Gemini API model and supports Google Search grounding in Google's current model and grounding documentation. See [Gemini models](https://ai.google.dev/gemini-api/docs/models) and [Google Search grounding](https://ai.google.dev/gemini-api/docs/google-search).

## 3. Firebase services

- **Firebase Core:** application initialization using `lib/firebase_options.dart`.
- **Firebase Authentication:** anonymous sign-in, Google sign-in, phone verification/sign-in, email/password sign-in, and password-reset flow in `lib/menu/my_account_screen.dart`.
- **Firebase ID tokens:** shared API service obtains an ID token for Worker requests.
- **Firebase Secure Token signing keys:** Worker fetches Google's public JWK set from `https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com` to verify RS256 signatures and validates Firebase project audience, issuer, subject and time claims.
- **Cloud Firestore:** per-user profile at `users/{uid}`; Phase 4 optionally stores DOB and preferred Telugu address. DOB stays in Firestore and only a coarse age band is sent to the Worker.
- **Firestore Security Rules:** `firestore.rules` restricts each user to their own `users/{uid}` document.

**Security limitation:** the Worker verifies token signature and claims, but revocation checking is not yet implemented. A trusted server-side Firebase Admin verification source or equivalent revocation-time source is required before production release.

## 4. Other external network API

- **Exchange rates:** `https://open.er-api.com/v6/latest/USD` in `lib/tools/currency_converter.dart`. This is a public exchange-rate data request and does not use the BUJJI Worker or Firebase Bearer token. The app validates the response and caches rates locally.

## 5. Native/device integrations (not separate BUJJI HTTP API routes)

- `speech_to_text`: device/platform speech recognition used by voice input and Voice Translation.
- `google_mlkit_text_recognition`: on-device text recognition/OCR integration.
- `image_picker`: camera/gallery image selection.
- `record`: device audio recording.
- `audioplayers`: audio playback.
- `path_provider`: device-local file paths.
- `share_plus`: operating-system share sheet.
- `shared_preferences`: device-local chat history, settings and bounded diagnostics.

These are Flutter/native plugin or local-storage integrations; this source audit did not identify a BUJJI-managed remote endpoint for them.

## 6. Security and configuration controls

- Worker Firebase authentication is controlled by `REQUIRE_FIREBASE_AUTH` and `FIREBASE_PROJECT_ID`.
- Worker rate limiting is controlled by `REQUIRE_RATE_LIMITING` and the `RATE_LIMITER` Durable Object binding / migration.
- CORS is an exact-origin allowlist from `CORS_ALLOWED_ORIGINS`; do not configure wildcard origins. Native clients without an `Origin` header remain supported.
- Gemini key is a Cloudflare secret. Never put it in Flutter, source control, logs, issue comments or build artifacts.
- Diagnostics and operational audit events must not contain message content, chat history, image bytes, access tokens, email addresses or Firebase UIDs.
- Chat history is bounded locally and Worker history is truncated to the configured limit.
- Rate-limit failure is fail-closed when rate limiting is required.

## 7. Live account observations and remaining tests

At the time of this audit, the connected Cloudflare account showed the Production Worker with the `AI` binding and `GEMINI_API_KEY` secret binding. The latest Production deployment observed was version `37921598-9c25-4a55-9e88-b6f15a0f9470` from 2026-11-13. The Phase 4 implementation branch has a successful Cloudflare Preview build, but it has not been promoted to Production.

Still required in a non-production environment:
1. Confirm Firebase Anonymous provider is enabled; run anonymous sign-in and profile read/write on a real test device.
2. Verify the staging Worker has `GEMINI_API_KEY`, `AI`, `RATE_LIMITER`, Firebase project vars and required Durable Object migration.
3. Test authenticated `/chat` and `/vision`, including missing/expired/wrong-project/invalid-signature tokens.
4. Test Gemini success, Google Search grounding, transient Gemini failure to OpenAI fallback, non-retryable Gemini client errors, and safe failure when both providers are unavailable.
5. Test Vision query and caption fallback with real image payloads.
6. Verify all Flutter Worker call sites return and record Trace IDs; test Voice Translation after the shared-auth transport correction.
7. Test CORS preflight for every actual browser origin, if a browser client is deployed.
8. Run restart/restore/clear history and diagnostics clear tests on a real Android device.
9. Review current provider retention, privacy, quota and billing terms before release.

No Production deployment, secret rotation, Firebase rules publication or main-branch merge is authorized by this inventory.
