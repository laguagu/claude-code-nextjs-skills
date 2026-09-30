---
name: next-best-practices
description: Next.js App Router best practices covering file conventions, RSC boundaries, async APIs, data patterns, hydration errors, metadata, route handlers, image/font optimization, and bundling. Use when writing or reviewing Next.js code to prevent hydration errors, RSC violations, data waterfalls, and configuration mistakes.
---

# Next.js review and implementation

Read the installed `next` version and relevant `node_modules/next/dist/docs/`
pages before changing framework behavior. Those docs and project configuration
take precedence; use a matching online version/source tag when local docs are
unavailable. The original Next-skills upstream is archived.

Review the actual failure or feature, rather than applying every optimization.
Keep the project's router, caching mode, runtime and package manager unless
migration is requested.

## Read for the affected area

| Area | Local reference |
| --- | --- |
| Route files, groups, proxy | [File conventions](file-conventions.md) |
| Server/client imports and props | [RSC boundaries](rsc-boundaries.md), [directives](directives.md) |
| Params and request APIs | [Async APIs](async-patterns.md), [functions](functions.md) |
| Reads, mutations and APIs | [Data patterns](data-patterns.md), [Route Handlers](route-handlers.md) |
| Rendering and failures | [Suspense](suspense-boundaries.md), [hydration](hydration-error.md), [errors](error-handling.md) |
| Metadata and public discovery | [Metadata](metadata.md); `nextjs-seo` for an SEO audit |
| Assets and loading | [Images](image.md), [fonts](font.md), [scripts](scripts.md) |
| Package/runtime behavior | [Bundling](bundling.md), [runtime](runtime-selection.md) |
| Navigation slots/modals | [Parallel routes](parallel-routes.md) |
| Deployment/debugging | [Self-hosting](self-hosting.md), [diagnostics](debug-tricks.md) |

Use `cache-components` when that mode is enabled and relevant to the task.
Tag invalidation can also operate on fetch caches outside that mode.

Validate a production build and the changed route's behavior. A dev render can
hide prerender/Suspense issues; a build cannot prove authorization, hydration,
freshness or cross-instance behavior. Report what was actually exercised.
