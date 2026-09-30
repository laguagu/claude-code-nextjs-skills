# Skill audit history

## 2026-09-30: verified API examples, release 1.0.9

Imported the source collection's next 15 commits through `9ae1048` and reviewed
the restoration in three groups: Python agents, AI SDK, and Next.js.
Preserved the concise examples in five implementation skills:
`openai-agents-sdk`, `ai-sdk-6`, `ai-sdk-7`, `cache-components`, and
`next-best-practices`. They demonstrate version-sensitive tool, stream,
session, cache, async-params and proxy contracts. Tutorials remain removed.

Kept provider dist-tag compatibility, the pinned AI Elements v6 constraint
and v7 usage-field patch, approval-signing version floors, the corrected
Search Console anchor, and the raw-fetch route. Example count is not a quality
target; authoring guidance distinguishes implementation from discovery-only
skills and identifies the version and kind of verification.

Review narrowed two factual claims: ordinary Python function-tool results use
stringification as a fallback, with structured/JSON exceptions; cache
persistence across instances and deployments depends on storage and cache
identity. The Iconify `finland` search remains a dated observation.

The Python example passed an offline run with openai-agents 0.22.3,
ScriptedModel, SQLiteSession and tracing disabled. Both AI SDK route/client
examples passed typechecking against ai 6.0.298 and 7.0.124; mock-model POSTs
returned HTTP 200 SSE with one tool step and a follow-up answer. Next.js claims
were reviewed against tagged 16.3.8 docs/source; the earlier review's build and
server tests were not rerun. No live provider, production app or agent-output
quality test was performed.

Format and local-file link checks passed for all 50 source skills, including
11 intentional client extensions. All 395 files in the 24 published skills
match committed source content. Plugin/marketplace manifests and private-skill
reference checks passed; the actual skill targets cover the validator's local
junction warning.

## 2026-09-30: reconcile the two restoration reviews

Compared the published baseline `011f5f9`, the five commits ending at
[`cd709e4`](https://github.com/laguagu/claude-code-nextjs-skills/commit/cd709e4)
on `ccr-62caabe6-a78tc5`, and the shared source collection's same-day changes.
The branch had no pull request. Changes were reviewed per skill, preserving
useful findings from both versions and the existing design direction.

Kept concise API names, version boundaries, owner defaults, measured findings
with their scope, and working local procedures. Installed documentation,
types, source and CLI help take priority over a generic current web recipe.
Long tutorials and duplicated application scaffolds remain removed.

Material corrections from this review:

- New AI apps retain the SDK 7 default; existing projects retain their chosen
  major. Core and UI callback names have separate version boundaries.
- Exact tool, approval, stream identity and persistence contracts are retained.
  OpenAI `StopAtTools` uses `stop_at_tool_names`; disabling strict model schemas
  does not remove the SDK's JSON validation. Missing tracing credentials cause
  warning/skip rather than necessarily an HTTP 401.
- Next.js cache and invalidation guidance retains build-versus-runtime gotchas,
  installed-version lookup and useful examples, without prescribing `cacheLife`
  for every cache or treating build ID and deployment ID as the same feature.
- Icons use verified identifiers. svgl is primarily a brand/technology source;
  it is not categorically unable to return a file-type mark.
- Search measurements retain their corpus, latency and hardware conditions.
  Hybrid tied vector on the recorded long-question set; it did not beat it.
- Authoring guidance prefers an exact name or short example when it explains a
  non-obvious contract. It does not require a snippet for every ordinary API.

Bundled upstream skills retain their licenses and intentional local patches.
This review did not refresh unrelated upstream packages or rewrite the
Supabase collection.

Validation: all 50 repo-owned source skills passed metadata and local-file
link checks (39 portable; 11 intentional client extensions). All 395 files
in the 24 published skills match the source Git index. Plugin and marketplace
manifests, private-skill references, staged secret scanning and diff checks
passed. Manifest validation noted root CLAUDE.md context and local junctions;
the actual skill targets were validated separately. Small isolated Node
module-loading and Bun JSON-LD checks also passed. No application, provider
or cloud behavior was exercised, and historical benchmarks were not rerun.

## 2026-09-29–30: simplification and first follow-up

The simplification removed repeated tutorials, application templates and
arbitrary style rules while retaining the user's restrained UI preferences.
Typography, backgrounds, visual effects, media and purposeful motion remain
available choices. The redundant taste skill was retired.

The first follow-up fixed version-specific documentation routes and restored
small useful behavior notes. Relevant public revisions:
[`e982629`](https://github.com/laguagu/claude-code-nextjs-skills/commit/e982629),
[`a55bfd3`](https://github.com/laguagu/claude-code-nextjs-skills/commit/a55bfd3),
[`460c741`](https://github.com/laguagu/claude-code-nextjs-skills/commit/460c741),
[`011f5f9`](https://github.com/laguagu/claude-code-nextjs-skills/commit/011f5f9).

This is a content and compatibility review, not a measured comparison of agent
output quality. Historical application benchmarks remain observations from
their original experiments.
