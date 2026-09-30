---
name: next-best-practices
description: Next.js App Router best practices covering file conventions, RSC boundaries, async APIs, data patterns, hydration errors, metadata, route handlers, image/font optimization, and bundling. Use when writing or reviewing Next.js code to prevent hydration errors, RSC violations, data waterfalls, and configuration mistakes.
---

# Next.js review and implementation

Read the installed `next` version and the relevant docs before changing
framework behavior; they and the project configuration take precedence.

Review the actual failure or feature, rather than applying every optimization.
Keep the project's router, caching mode, runtime and package manager unless
migration is requested.

## Sources

Next.js 16.2+ bundles version-matched docs in `node_modules/next/dist/docs/` (in
a monorepo, resolve `next` from the app package). Doc paths in this skill are
relative to its `01-app/`, e.g. `03-api-reference/04-functions/`. Exact exports:
`node_modules/next/{server,navigation,headers,cache}.d.ts`; CLI: `next --help`.
On older versions, or without the package, use the official docs:
`https://nextjs.org/docs/app/` + the path with numeric prefixes and `.md`
removed (append `.md` for Markdown). A named file missing locally usually means
the feature postdates the installed version. Build errors carry their fix; only
the linked `/docs/messages/` pages are web-only.

## Version facts

| Area | Next.js 16 |
| --- | --- |
| Request APIs | `cookies()`, `headers()`, `draftMode()`, `params`, `searchParams` are async only (15 kept a sync fallback). Types: global `PageProps<'/blog/[slug]'>`, `LayoutProps`, `RouteContext` |
| Middleware | `middleware.ts` → `proxy.ts` with `export function proxy`; Node.js only, no `runtime` option. Edge only via the deprecated `middleware.ts` |
| Runtime | `export const runtime = 'edge'` is deprecated; remove it |
| Bundler | Turbopack for `dev` and `build`; a custom `webpack` config fails `next build` without `--webpack` or `--turbopack`. `turbopack` is top-level config |
| Removed | `next lint` (`next build` no longer lints), `serverRuntimeConfig`/`publicRuntimeConfig`, AMP |
| Minimums | Node.js 20.9, TypeScript 5.1 |

Upgrade path: `02-guides/upgrading/version-16.md`.
`npx @next/codemod@canary upgrade latest` does not migrate sync request-API
access; run `next-async-request-api` separately (see [async APIs](async-patterns.md)).

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

Use `cache-components` when `cacheComponents` is enabled and relevant to the
task. Tag invalidation can also operate on fetch caches outside that mode.

Validate with the project's lint/typecheck scripts and a production build, then
exercise the changed route under `next start`. A dev render can hide
prerender/Suspense issues; a build cannot prove authorization, hydration,
freshness or cross-instance behavior. Report what was actually exercised.
