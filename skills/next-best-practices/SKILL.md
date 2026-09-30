---
name: next-best-practices
description: Next.js App Router best practices covering file conventions, RSC boundaries, async APIs, data patterns, hydration errors, metadata, route handlers, image/font optimization, and bundling. Use when writing or reviewing Next.js code to prevent hydration errors, RSC violations, data waterfalls, and configuration mistakes.
---

# Next.js review and implementation

Read the installed `next` version and relevant `node_modules/next/dist/docs/`
pages before changing framework behavior. Those docs and project configuration
take precedence; use a matching online version/source tag when local docs are
unavailable. The original Next-skills upstream is archived.

Docs are bundled from 16.2; in a monorepo, read the app's own `next` package.
The nextjs.org links in these files have local equivalents with numbered
folders, so search by file name (`find node_modules/next/dist/docs -name proxy.md`).
`01-app/02-guides/upgrading/version-16.md` lists the breaking changes.
Per-error pages (`/docs/messages/*`) are only online; the dev/build output
carries the error's fix options.
Exact exports are also in `node_modules/next/{server,navigation,headers,cache}.d.ts`.

## Next.js 16 changes older examples miss

- Sync request access is removed: `cookies()`, `headers()`, `draftMode()`,
  `params` (including image-metadata routes), `searchParams` and sitemap `id`
  are promises. `next typegen` generates global `PageProps<'/route'>`,
  `LayoutProps` and `RouteContext` types.
- `middleware.ts` is deprecated: `proxy.ts` exporting `proxy` (or default)
  runs on Node.js only and rejects a `runtime` option; code that needs Edge
  stays in `middleware.ts`. Codemod: `npx @next/codemod@latest middleware-to-proxy .`.
- Turbopack is the default for `dev` and `build`; a custom `webpack` config
  fails the build unless `--webpack` keeps it or explicit `--turbopack` ignores
  it. `next lint` is removed and
  `next build` no longer lints. `serverRuntimeConfig`/`publicRuntimeConfig`
  are removed.
- Every parallel-route slot needs `default.tsx`, or the build fails.
- `next/image`: `priority` is deprecated for `preload`; `qualities` defaults to
  `[75]` (other `quality` values are coerced); local `src` with a query string
  needs `images.localPatterns`; `images.domains` is deprecated for
  `remotePatterns`.
- `revalidateTag(tag)` is deprecated; pass a profile such as `'max'` or
  `{ expire: 0 }` for immediate expiry. `updateTag` and `refresh` are Server
  Action-only. Caching details: `cache-components`.

The params and proxy shapes, checked against next 16.3.8 (`next typegen`,
`tsc --noEmit`, `next build`):

```tsx
// app/blog/[slug]/page.tsx; PageProps is global after `next typegen` (or dev/build)
export async function generateStaticParams() {
  return [{ slug: 'hello' }] // cacheComponents: needed for this top-level await; never []
}

export default async function Page({ params }: PageProps<'/blog/[slug]'>) {
  const { slug } = await params // a Promise; sync access was removed in 16
  return <h1>{slug}</h1>
}

// proxy.ts, replacing middleware.ts: Node.js runtime, no `runtime` export
import { NextResponse, type NextRequest } from 'next/server'

export function proxy(request: NextRequest) {
  // Optimistic check only: authorize again where the data is read.
  if (request.cookies.has('session')) return NextResponse.next()
  return NextResponse.redirect(new URL('/login', request.url))
}

export const config = { matcher: ['/dashboard/:path*'] }
```

The `upgrade` codemod does not migrate synchronous request-API access; run
`next-async-request-api` separately when migrating that code. Use the project's
package runner and review the resulting types and runtime behavior.

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

Validate with the project's lint/typecheck scripts and a production build,
then exercise the changed route under `next start`. A dev render can
hide prerender/Suspense issues; a build cannot prove authorization, hydration,
freshness or cross-instance behavior. Report what was actually exercised.
