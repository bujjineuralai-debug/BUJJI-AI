# BUJJI AI Phase 4 — Architecture & Privacy Audit

## Current account/profile data observed in the app source

The current My Account flow reads and stores display name and email locally. When Firebase Authentication is active, the profile document at `users/{uid}` may also contain UID, email, phone number, photo URL, email-verification state, provider IDs, display name and timestamps. Firestore rules restrict each signed-in user to their own profile document.

## Date of birth and age-band status

- No date-of-birth field or age field was found in the current My Account profile form or profile write payload.
- No age-band derivation is currently implemented.
- The app must not infer a person's age from their name, writing style, voice, photo or other indirect signals.
- Until the user explicitly opts into a future age setting, use respectful neutral language and do not invent an age-based title.
- If DOB collection is approved in a later product decision, it must be optional, clearly explained, purpose-limited, access-controlled and deletable. Prefer deriving a coarse age band locally and avoid sending/storing the full DOB unless a documented need is approved.

## Preferred form of address

A future user-selected form-of-address preference should override any derived age-band title. It must be optional and user-editable. Age-appropriate vocatives, when supported by an explicitly supplied preference or age band, are allowed only in the first assistant message of a conversation/session. From the second assistant message onward, do not repeat the title; remain respectful and natural.

## Authentication & API transport

- Chat, Writing Assistant, Feature Assistant and Vision use the shared `BujjiApiService`.
- The service obtains a Firebase ID token and sends it as a Bearer token.
- If no Firebase user exists, the app establishes a Firebase anonymous session; users can later link supported credentials through My Account.
- The Worker verifies RS256 signatures using Google's Firebase Secure Token signing keys and checks project audience, issuer, subject and token time claims.
- The Worker requires Firebase auth and rate limiting in the checked-in Wrangler configuration. These settings take effect only after an authorized deployment.
- Firebase Console must have Anonymous sign-in enabled for guest sessions to work.

## Diagnostics and redaction

Local diagnostics retain at most 50 request records: endpoint path, UTC timestamp, duration, HTTP status, outcome, error class and request Trace ID. They do not store request payloads, prompts, chat history, images, access tokens, email addresses or Firebase UIDs. Users can copy a Trace ID or clear local diagnostic history.

Worker operational audit events use Trace IDs and non-content metadata. Vision diagnostics record result shape and answer length, not image bytes or the question text.

## Remaining validation

- Complete Flutter analyzer and test workflow.
- Run staging integration tests against a staging Firebase project and Cloudflare Worker.
- Verify anonymous provider enablement and credential linking.
- Automated Worker tests cover wrong-project, invalid-signature, expired and missing Firebase tokens; repeat these against the staging Firebase project.
- A dedicated Telugu Language Intelligence module now supplies separate grammar, orthography, pronoun, honorific, Romanized Telugu and silent-proofreading guidance to the Worker system prompt. Automated Worker coverage checks that the module is present in the Gemini prompt and includes vowel signs, conjuncts, doubled consonants and respectful-address rules.
- Runtime review with native Telugu speakers remains necessary; the prompt is guidance for the model, not a deterministic Telugu spell-checker or a guarantee of perfect orthography.
- Test end-to-end Trace ID correlation and all supported languages.
- Resolve the existing Gemini-primary Cloudflare AI binding dependency last, without removing the AI binding needed by Llama fallback and Vision.
