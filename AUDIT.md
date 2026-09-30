# Skill audit history

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
