---
name: cache-components
description: "Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). Use when implementing 'use cache' directive, configuring cache lifetimes with cacheLife(), tagging cached data with cacheTag(), invalidating caches with updateTag()/revalidateTag(), optimizing static vs dynamic content boundaries, instant navigation validation, 'use cache: private', pass-through/interleaving patterns, GET Route Handler caching, debugging cache issues, and reviewing Cache Component implementations."
metadata:
  version: "1.0"
---

# Cache Components

Keep the project's caching mode unless migration is requested. Check the
installed `next` version and `cacheComponents` in `next.config.*` first.

The goal is a useful prerendered shell with freshness and authorization rules
that remain correct after mutations, deploys and client navigation.

## Sources

Next.js 16.2+ bundles version-matched docs in `node_modules/next/dist/docs/` (in
a monorepo, resolve `next` from the app package). Doc paths in this skill are
relative to its `01-app/`; start with `01-getting-started/08-caching.md` and,
for a migration, `02-guides/migrating-to-cache-components.md`. Exact exports and
profile values: `node_modules/next/cache.d.ts`. On 16.0–16.1, or without the
package, use the official docs: `https://nextjs.org/docs/app/` + the path with
numeric prefixes and `.md` removed (e.g. `api-reference/functions/cacheLife`;
append `.md` for Markdown). A named file missing locally usually means the
feature postdates the installed version. Build/dev errors print their fix
options inline; only the linked `/docs/messages/` pages are web-only.

## Version facts

| Legacy or commonly guessed | Next.js 16 with `cacheComponents: true` |
| --- | --- |
| `experimental.ppr`, `experimental_ppr`, `experimental.dynamicIO`/`useCache` | Removed; top-level `cacheComponents: true` |
| `unstable_cacheLife`, `unstable_cacheTag` | `cacheLife`, `cacheTag` from `next/cache` |
| Segment `dynamic`, `revalidate`, `fetchCache`, `dynamicParams` | Build error. Use `use cache` + `cacheLife`, Suspense, `notFound()` |
| `runtime = 'edge'` | Unsupported; Cache Components needs Node.js |
| `unstable_cache`, `fetch` `next: { revalidate, tags }` | `use cache` + `cacheLife`/`cacheTag`. Those old caches survive deploys; `use cache` entries do not (build ID is in the key) |
| `generateStaticParams` returning `[]` | Error; return at least one real param |
| `revalidateTag(tag)` | Deprecated; behaves like `{ expire: 0 }`. Pass a profile |
| `connection()` before `Date.now()`/`Math.random()` | 16.3+: `await io()` from `next/cache`; keep `connection()` for waiting on a real request |
| `export const unstable_instant` (16.2) | `export const instant` (16.3+) |

```tsx
import { cacheLife, cacheTag } from 'next/cache'

export async function getPost(id: string) {
  'use cache'
  cacheLife('hours')
  cacheTag(`post-${id}`)
  return db.post.findUnique({ where: { id } })
}
```

## Decide the boundary

- Cache reusable results when the product's freshness and data policy permit.
  Static content needs no directive just to be static.
- A plain `use cache` scope cannot call `cookies()`, `headers()`,
  `searchParams` or `connection()`, even through a helper
  (`next-request-in-use-cache`). On a dynamic route this passes `next build`
  and fails under `next start`. Read outside and pass authorized, serializable
  values; arguments and captured variables become the key.
- Uncached I/O or request data outside `<Suspense>` is a prerender error, not a
  silently dynamic route. Pass the `params`/`searchParams` promise to the
  Suspense-wrapped child and await it there. Synchronous `Date.now()`,
  `Math.random()` or `crypto.randomUUID()` fails the prerender even inside
  Suspense unless request/uncached data or `await io()` precedes it, or
  `use cache` captures it.
- `'use cache: private'` may read cookies/headers but stores nothing on the
  server; `'use cache: remote'` is per-instance memory unless the host or
  `cacheHandlers.remote` provides a store. See [REFERENCE.md](REFERENCE.md).

## Define freshness and invalidation

Set `cacheLife` in every `use cache` scope. Named profiles can be redefined in
`next.config.*`; read it before assuming a duration.

Use tags when invalidation must reach the same entity across routes, path
invalidation for route-specific output, or expiry where that meets the contract.
Authenticate, authorize and validate before mutations. Invalidate only affected
cached data:

- `updateTag`: immediate expiry/read-your-writes, Server Actions only (throws elsewhere).
- `revalidateTag(tag, 'max')`: stale-while-revalidate on a later visit.
- `revalidateTag(tag, { expire: 0 })`: immediate expiry where a webhook/Route
  Handler needs it.

These tag APIs also apply to `fetch` data tagged with `next.tags`; their
availability does not by itself mean Cache Components is enabled.

## Read for the problem

- [API boundaries](REFERENCE.md): keys, lifetimes and thresholds, variants, routes.
- [Composition](PATTERNS.md): params and shells, tenant isolation, state, deployment.
- [Troubleshooting](TROUBLESHOOTING.md): error names with their causes and fixes.

Finish with `next build`: the route table marks `◐` shell plus streaming, `○`
static, `ƒ` nothing prerendered. Then `next start` and exercise direct load,
client navigation, the mutation and the following read, with a second identity
when output is per-user. Dev-only insights appear in the overlay, terminal or
MCP `get_errors`; the route still returns 200. A passing build cannot prove
freshness, tenant isolation or multi-instance invalidation.
