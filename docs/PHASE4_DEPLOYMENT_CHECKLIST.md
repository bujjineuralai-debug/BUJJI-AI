# BUJJI AI Phase 4 — Staging & Production Checklist

This checklist is for an authorized maintainer. The Phase 4 branch is not a production deployment.

## Firebase project setup

- Firebase project ID: `bujji-ai-2e2af`.
- In Firebase Console → Authentication → Sign-in method, enable **Anonymous** sign-in before testing guest sessions.
- Keep existing Google and Email/Password providers enabled as required by the app.
- Verify anonymous users can link Google or Email/Password credentials through My Account.
- Publish the repository's `firestore.rules` only after reviewing the target Firebase project and confirming the rule set. The rules restrict each user to their own `users/{uid}` profile document.
- Do not add service-account JSON or private signing keys to the mobile app or repository.

## Cloudflare staging setup

- Configure the Worker secrets in the staging environment, including `GEMINI_API_KEY`.
- Confirm the public variable `FIREBASE_PROJECT_ID=bujji-ai-2e2af` and `REQUIRE_FIREBASE_AUTH=true`.
- Keep `REQUIRE_RATE_LIMITING=true`.
- Create the Durable Object binding `RATE_LIMITER` for class `RateLimiter` and apply the `v1` SQLite migration.
- Verify the Cloudflare AI binding remains available for the Llama fallback and the separate Vision route.
- Run Wrangler validation and deploy only to a staging Worker first.

## Staging acceptance tests

- Anonymous Firebase session obtains an ID token and the Worker accepts a valid RS256 token.
- Missing, expired, wrong-project, malformed and invalid-signature tokens receive HTTP 401.
- Chat and Vision both reject unauthenticated requests.
- Rate limiting returns HTTP 429 with Retry-After and fails closed if the Durable Object is unavailable.
- Gemini success, Gemini failure → Llama fallback, and both-provider failure paths behave as expected.
- Request-size validation, Telugu / Roman Telugu / English / mixed-language behavior, app restart history restore and Trace ID diagnostics pass.
- Confirm diagnostics contain only endpoint path, timestamp, duration, status, outcome, error category and Trace ID; never prompts, history, images, tokens, email or UID.

## Production gate

- The Cloudflare deployment workflow is manual-dispatch only and targets the GitHub `production` environment.
- In GitHub repository Settings → Environments, configure `production` with required reviewers before running the deployment workflow; the workflow file alone cannot enforce reviewer membership.
- Require a reviewed pull request and explicit human approval.
- Back up current Worker configuration and preserve the previous deploy for rollback.
- Apply Durable Object migration and Firebase provider configuration before enabling mandatory auth/rate limiting.
- Deploy the Worker and Flutter release in a coordinated order; verify the app version sends Firebase Bearer tokens before routing production traffic to a Worker requiring them.
- Run production smoke tests, monitor redacted Trace ID events and keep a rollback path ready.
- Never deploy automatically from this branch.
