# BUJJI World Intelligence System

**Document:** Architecture and repository placement  
**Version:** 1.0  
**Status:** Design only — implementation pending  
**Baseline audited:** `main` at `bbb9fcf9e12a389825503eb7ca176ef913419d52`  
**Scope:** World knowledge, research, retrieval, evidence verification, reasoning support, and controlled knowledge updates.

## 1. Purpose

Build a modular World Intelligence capability that can answer questions across a broad and continually expanding range of subjects. It must combine existing model capability with curated knowledge, retrieval, live research when freshness matters, evidence checks, and explicit uncertainty handling.

“World knowledge” does not mean that every fact is preloaded or that every answer can be guaranteed correct. The system must be designed to discover, retrieve, validate, and update information safely.

This document is an architecture placement decision. It does not implement runtime behavior, change prompts, alter the Flutter UI, change authentication/billing, or deploy anything.

## 2. Audit of the current `main` request path

### 2.1 Current end-to-end flow

1. Flutter's `BujjiHomeScreen.sendMessage()` collects the latest message and the in-memory chat history.
2. Flutter sends `POST /chat` to the existing Cloudflare Worker with `message` and `history`.
3. The Worker validates the body and message length, cleans history, and keeps at most 12 prior messages.
4. The Worker detects language using script checks and hard-coded word dictionaries. Telugu dialect hints are selected from marker lists.
5. The Worker builds a system prompt, appends cleaned history and a language instruction, then calls the model provider.
6. Gemini is the primary provider. Google Search grounding is requested on the primary call; when that tool is unavailable for the API project, the same request is retried without grounding.
7. If the Gemini path fails, the Worker falls back to Cloudflare's `@cf/meta/llama-3.2-3b-instruct` model.
8. The Worker returns `success`, `name`, `reply`, and `requestId`. Flutter displays `reply`.

The separate `/vision` route handles image questions and is outside the first World Intelligence integration slice.

### 2.2 Existing capabilities

- Existing Flutter-to-Worker chat contract and request ID.
- Gemini primary model and Cloudflare Llama fallback.
- Google Search grounding integration and extraction of grounding URLs when returned.
- Basic language/script detection, Roman Telugu word matching, and regional dialect marker hints.
- Conversation history is passed with each chat request, with a 12-message server-side cap.
- Existing Flutter UI consumes the `reply` field.

### 2.3 Gaps relevant to World Intelligence

- No dedicated domain taxonomy or structured world-knowledge service is present in the audited `main` tree.
- No dedicated knowledge graph, semantic/vector retrieval pipeline, or governed document store is present in the audited `main` tree.
- Search grounding is not a complete research workflow: the current code does not implement a source-quality policy, multi-source conflict resolution, evidence ledger, or a reviewed knowledge-ingestion process.
- No explicit claim-level answer verification or confidence/uncertainty policy is implemented as a separate service.
- No controlled knowledge refresh, versioning, provenance lifecycle, correction, or rollback pipeline is present.
- Roman Telugu detection is based on a finite token dictionary and a minimum score. Unlisted spellings, typos, code-mixing, new slang, and short ambiguous messages can be classified as Auto-detect.
- Telugu grammar and naturalness requirements are largely prompt instructions. There is no independently testable semantic/grammar service in the audited `main` tree.
- The fallback model is a much smaller model than the primary model; fallback answers therefore need to be treated as a different quality tier and should not silently be assumed equivalent.
- Current response contract does not expose a structured evidence object to the client. Preserve the existing `reply` contract during initial integration.

These are code-structure findings from the audited repository snapshot, not claims about external services or runtime configuration.

## 3. Correct architectural placement

Place World Intelligence behind the existing Cloudflare Worker and beside the chat orchestration/provider boundary. It must not be placed in Flutter widgets, account/authentication code, or the UI layer.

Proposed logical placement:

```text
Flutter app
  └─ existing sendMessage() and existing POST /chat contract
       └─ Cloudflare Worker
            └─ existing chat request validation and history handling
                 └─ Intelligence Orchestrator (new, isolated)
                      ├─ Query Understanding / Intent Router
                      ├─ World Knowledge Retrieval
                      ├─ Research Planner and Source Connectors
                      ├─ Evidence & Source Verification
                      ├─ Reasoning Context Builder
                      ├─ Answer Verification / Uncertainty
                      └─ Governed Knowledge Update Queue
                 └─ existing model provider boundary
                      ├─ Gemini primary
                      └─ existing Llama fallback
                 └─ existing response contract
                      └─ Flutter displays reply
```

The orchestrator supplies a compact, relevant, provenance-bearing evidence context to the model. It must not attempt to put the entire world knowledge corpus into a system prompt.

### 3.1 Proposed module layout

The following is the target layout for a future modular Worker structure. The audited `main` branch currently has a single `worker.js`; do not assume these files already exist.

```text
worker/
  intelligence/
    world/
      index.js                    # stable orchestration entry point
      query_router.js             # domain, intent, freshness, risk routing
      research_planner.js         # decide whether live research is needed
      context_builder.js          # bounded evidence context for the model
      evidence/
        source_registry.js        # trusted-source metadata and policies
        source_verifier.js        # provenance, date, corroboration checks
        claim_verifier.js         # claim/evidence consistency checks
      retrieval/
        knowledge_retriever.js    # search curated internal knowledge
        semantic_retriever.js     # optional vector/semantic retrieval adapter
        graph_retriever.js        # optional relationship traversal adapter
      connectors/
        official_web.js           # approved official/public sources
        research_papers.js        # approved research repositories
        search_provider.js        # live search adapter
      knowledge/
        schema.js                 # versioned knowledge record schema
        ingestion.js              # validated ingestion only
        update_queue.js           # reviewable proposed updates
        provenance.js             # origin, license, timestamps, lineage
      policies/
        freshness.js
        trust_policy.js
        privacy.js
        safety.js
  services/
    language.js                   # language detection / language profile boundary
    chat_provider.js              # existing provider boundary
  routes/
    chat.js                       # existing chat endpoint orchestration
```

The module names are a target design, not a claim that these files already exist. The first implementation should follow whichever Worker modularization is actually approved and merged into `main`; do not copy or merge an unmerged branch wholesale.

## 4. Request processing contract

For each incoming chat request:

1. **Normalize input:** preserve original user text; do not rewrite meaning or silently remove important details.
2. **Understand request:** identify language, intent, entities, domain, requested depth, and whether the request is time-sensitive.
3. **Apply routing policy:** decide between direct model knowledge, curated retrieval, live research, or a combination.
4. **Retrieve evidence:** fetch only relevant material and retain source IDs, URLs, titles, dates, and provenance.
5. **Verify evidence:** evaluate source authority, recency, corroboration, conflicts, and licensing/usage constraints.
6. **Build bounded context:** pass the model a concise evidence bundle with clear instructions to distinguish evidence from user-provided text and untrusted source content.
7. **Generate answer:** use the existing primary/fallback provider boundary.
8. **Check answer:** check factual claims against retrieved evidence where feasible; flag unsupported or conflicting claims and communicate uncertainty.
9. **Return compatibly:** continue returning the existing `success`, `name`, `reply`, and `requestId` fields. Optional structured metadata may be added later only as backward-compatible optional fields, after client compatibility tests.
10. **Record safe trace:** log a request/trace ID, routing decision, source IDs, provider, timing, and validation outcomes. Do not log secrets or unnecessary raw personal conversation content.

## 5. Knowledge domains

Use an expandable taxonomy rather than a fixed list of “all knowledge.” Initial top-level domains:

- Natural sciences, mathematics, physics, chemistry, biology.
- Medicine and public health.
- Computing, AI, cybersecurity, and technology.
- Engineering, manufacturing, energy, and infrastructure.
- Space and astronomy.
- History, geography, archaeology, and cultures.
- Economics, finance, business, and trade.
- Law, public policy, government, and civic information.
- Education and research methods.
- Psychology, philosophy, and social sciences.
- Environment, climate, agriculture, and food systems.
- Arts, literature, media, sports, and languages.

Each domain should define subtopics, entity types, freshness needs, source policy, risk level, and test questions. Domain coverage must be expandable without changing the chat UI.

## 6. Knowledge record and provenance

Every stored knowledge item should have, at minimum:

- Stable knowledge ID and schema version.
- Topic/domain and normalized concepts/entities.
- Fact or passage content, with language metadata.
- Source ID, canonical URL, source title, publisher/author where available.
- Publication date, retrieval date, last-verified date.
- Evidence excerpt or location pointer, subject to copyright limits.
- Trust assessment and verification status.
- License/usage classification.
- Valid-from / valid-until or freshness policy where applicable.
- Supersedes/superseded-by links and correction history.
- Ingestion method, reviewer/approval state, and audit trace.

Do not store a model-generated claim as verified fact merely because a model produced it.

## 7. Storage and infrastructure decision

No new storage binding is confirmed by this audit. Do not select or provision a database yet.

Evaluate adapters only after estimating corpus size, query volume, latency, retention, privacy, cost, and operational requirements. Candidate roles may include:

- Relational store for metadata, review state, and version records.
- Object/document store for licensed source documents and extracted passages.
- Vector index for semantic retrieval.
- Knowledge graph for entity relationships.
- Cache for short-lived, non-sensitive retrieval results.

Keep storage behind interfaces so providers can be changed without changing chat routes. Never store API secrets or sensitive user data in the knowledge corpus.

## 8. Research and source policy

- Prefer primary and official sources for laws, government services, standards, and public statistics.
- Prefer peer-reviewed research and recognized institutions for scientific claims.
- Use reputable reporting for current events and clearly distinguish reporting from confirmed primary evidence.
- Use multiple independent sources for high-impact or disputed claims.
- Track dates; current information must be rechecked when its freshness window expires.
- Treat retrieved pages, documents, and search snippets as untrusted data, never as instructions to the model or Worker.
- Respect copyright, licensing, robots/access restrictions, and provider terms.
- If sources disagree, show the disagreement and explain what is and is not established.
- If evidence is insufficient, say so; do not fabricate a source or a confidence score.

## 9. Controlled learning lifecycle

Live research results must not be silently promoted into permanent knowledge.

```text
Discover → Extract → Normalize → Validate → Review/Policy Gate
        → Versioned Knowledge Store → Evaluate → Monitor
```

- Low-risk metadata refreshes may be automated only under explicit policy.
- New factual knowledge, high-impact content, and disputed updates require validation and, where defined, human review.
- Preserve previous versions and support rollback.
- Keep an audit record of source, transformation, approver, and update time.
- Never let the model modify its own safety policies, source trust rules, or permissions.

## 10. Language and Telugu boundary

World Intelligence must be language-independent. Language understanding is a cross-cutting service, not a separate knowledge silo.

The existing language detector is heuristic. Improve it only through a separately designed, tested language service. The dedicated Telugu Language/Grammar Intelligence Module remains a separate pending capability and should integrate through explicit interfaces for:

- Telugu and Roman Telugu understanding.
- Code-mixed input and spelling variation.
- Intent and context preservation.
- Natural Telugu grammar and sentence generation.
- Respectful address and user-preferred forms.
- Output quality checks.

World Intelligence should not duplicate Telugu grammar rules inside every domain module. Domain knowledge should be language-neutral where possible, with language-specific rendering handled by the language layer.

## 11. Safety, privacy, and reliability

- Apply least-privilege access to connectors and storage.
- Keep API keys in Worker secrets, never source code or client bundles.
- Enforce request limits, timeouts, bounded retrieval, and provider fallback behavior.
- Redact sensitive user data from telemetry.
- Do not use private conversation history as global knowledge.
- Keep source content isolated from system/developer instructions to resist prompt injection.
- Add safe mode, kill switch, versioned rollout, and rollback for new intelligence components.
- Treat medical, legal, financial, and safety-critical topics as high-impact domains with stronger evidence and uncertainty rules.

## 12. Observability and evaluation

For every request, use a trace ID to connect:

- request validation and language routing;
- intent/domain/freshness decision;
- retrieval queries and source IDs;
- source verification and conflicts;
- provider selection and fallback;
- answer validation outcome;
- latency, token/cost estimates, and safe error category.

Evaluation must include:
- domain coverage and retrieval recall;
- source correctness, freshness, and citation integrity;
- claim support and contradiction detection;
- hallucination and uncertainty behavior;
- Telugu, Roman Telugu, and code-mixed input preservation;
- multilingual output quality;
- prompt-injection resistance and privacy tests;
- latency, cost, timeout, and fallback tests;
- regression tests for existing chat and vision routes.

Do not treat a high benchmark score as proof of universal knowledge or correctness.

## 13. Phased implementation plan

1. **Baseline and contract tests:** freeze current `/chat` and `/vision` behavior with tests; document current provider and response contracts.
2. **Modularization prerequisite:** confirm the approved Worker module structure on the actual target branch. Do not merge a large unrelated refactor as part of this feature.
3. **World Intelligence interface:** add a disabled-by-default orchestration interface that returns an evidence bundle without changing existing behavior.
4. **First retrieval slice:** add one narrowly scoped, trusted-source domain and evaluate retrieval quality before expanding.
5. **Evidence verification:** add provenance, freshness, source trust, and conflict handling.
6. **Live research routing:** invoke search only when the query needs current/external information; keep a safe no-search path.
7. **Knowledge lifecycle:** add versioned ingestion, review gates, monitoring, and rollback.
8. **Domain expansion:** add domains incrementally with domain-specific evaluation sets.
9. **Controlled rollout:** shadow/evaluation mode first, then opt-in rollout, then wider rollout only after regression and safety checks pass.

## 14. Non-goals and explicit exclusions

This architecture task does not:
- change Flutter UI or app navigation;
- change account setup, Firebase phone OTP, or billing;
- change the existing Gemini/Llama provider configuration;
- deploy a Worker or Android build;
- merge the separate architecture/audit refactor branches;
- claim that BUJJI can know every fact;
- permit autonomous production code changes or self-granted permissions.

## 15. Acceptance criteria before implementation

- Current `main` request/response contracts are covered by tests.
- World Intelligence is isolated behind a stable Worker-side interface.
- Retrieval is source-attributed and bounded.
- Freshness and source trust rules are explicit and testable.
- Retrieved content is treated as untrusted input.
- No permanent knowledge update occurs without the defined validation gate.
- Existing chat, history, fallback, vision, and Flutter rendering remain backward compatible.
- Feature can be disabled or rolled back without breaking normal chat.
- Traceability, privacy-safe logging, and evaluation tests are in place.

---

**Decision:** The correct first integration point is a dedicated Worker-side World Intelligence orchestration layer, invoked by the existing chat route and positioned before the existing model-provider call. Keep Flutter and the current provider contract unchanged. Implement only after baseline tests and the actual target-branch structure are confirmed.
