# Phase 4 — Stage 1 and Stage 2 implementation notes

## Implemented on the feature branch

- My Account supports an optional date of birth and a Telugu address preference.
- Date of birth is stored in the signed-in user's Firestore profile. It is not sent to the Worker.
- The app derives a coarse age band locally and sends only that band plus the selected address preference.
- The Worker validates the age-band and preference values before using them.
- Age-based vocative guidance is applied only when the conversation history contains no earlier assistant reply. Later replies are instructed not to repeat an age-based title.
- Telugu grammar intelligence now has a separate model-guidance module covering intent preservation, Telugu sentence structure, spelling, honorifics, dialect handling, Roman Telugu and a silent quality check.
- Worker rate limiting now applies a per-user bucket and a wider per-IP abuse-protection bucket when a verified Firebase UID is available. Unauthenticated/optional-auth requests retain IP-based limiting.

## Deployment configuration still required

- `CORS_ALLOWED_ORIGINS` is already an explicit allowlist. Add the real browser-client origins in the Cloudflare Worker environment; do not use `*`. The repository does not identify a verified browser origin, so none is guessed here.
- Firebase token revocation checks require a trusted server-side Admin credential or equivalent revocation-time source. The Worker currently validates JWT signature and claims, but this branch does not invent or embed a service-account credential. Configure a least-privilege server-side verification path before production release.

## Validation

Run the Flutter test suite and analyzer, then the Worker test suite and staging integration checks. In particular verify anonymous Firebase profile reads/writes, signed-in DOB persistence, profile preference overrides, first-reply-only vocative behavior, per-user/IP rate-limit buckets, CORS preflight for each deployed web origin, and Gemini/Llama behavior.

No production deployment, main-branch change, or merge is authorized by this implementation branch.
