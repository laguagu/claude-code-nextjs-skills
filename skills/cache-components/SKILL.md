---
name: cache-components
description: "Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). Use when implementing 'use cache' directive, configuring cache lifetimes with cacheLife(), tagging cached data with cacheTag(), invalidating caches with updateTag()/revalidateTag(), optimizing static vs dynamic content boundaries, instant navigation validation, 'use cache: private', pass-through/interleaving patterns, GET Route Handler caching, debugging cache issues, and reviewing Cache Component implementations."
metadata:
  version: "1.0"
---

# Cache Components

Keep the project's caching mode unless migration is requested. Confirm the
installed Next.js version and `cacheComponents` configuration before applying
these patterns.

Read the relevant guide in `node_modules/next/dist/docs/` first (bundled since
16.2; in a monorepo, use the app's own `next` package). Web paths map to files
with numbered folders, so find them by name: `.../functions/cacheLife` is
`01-app/03-api-reference/04-functions/cacheLife.md`. Under `01-app/`, start
with `02-guides/migrating-to-cache-components.md`,
`01-getting-started/08-caching.md` and `02-guides/instant-navigation.md`.
Error pages under `/docs/messages` are not bundled; `next dev`/`next build`
print the fix options inline. Without local docs, use the
[official caching docs](https://nextjs.org/docs/app/getting-started/caching).
Exact exports and signatures are also in `node_modules/next/cache.d.ts`.

The goal is a useful prerendered shell with freshness and authorization rules
that remain correct after mutations, deploys and client navigation.

## Facts older examples get wrong

- Next.js 16 enables the mode with top-level `cacheComponents: true`. It replaces
  `experimental.dynamicIO`, `experimental.useCache` and `experimental.ppr`;
  `cacheLife`/`cacheTag` import from `next/cache` without `unstable_`.
- With it enabled, segment exports `dynamic`, `revalidate`, `fetchCache` and
  `dynamicParams` are errors, and Edge runtime is unsupported. `revalidate = N`
  becomes `cacheLife` (nearest or custom profile) inside `use cache`;
  `force-dynamic` and `fetchCache` are unnecessary; fetch
  `next: { revalidate, tags }` becomes `cacheLife`/`cacheTag` in a `use cache`
  function; request data goes under Suspense; `dynamicParams = false` becomes
  `notFound()` for unknown params.
- Existing `fetch` and `unstable_cache` caching still works as a separate layer,
  so do not mechanically rewrite every read. Its persistence across deployments
  and instances depends on retained/shared storage; self-hosted instances do not
  share it by default. `use cache` is in-memory by default; even a durable
  handler cannot reuse entries when the build/deployment ID changes.
- `generateStaticParams` must return at least one param: `[]` fails the build,
  and removing the export renders the route on every request.
- `revalidate: 0` or `expire` under 5 minutes makes a request-time hole instead
  of prerendered output; of the presets only `seconds` does. 16.3 adds `stale`
  thresholds (under 30 s: not prerendered; under 5 min: not in the App Shell).
- Synchronous `new Date()`, `Math.random()` or `crypto.randomUUID()` during
  prerender is an error: capture it in `use cache`, or defer with `await io()`
  (`next/cache`, 16.3+) or `await connection()` (`next/server`) under Suspense.
- `use cache: private` was experimental through 16.2. It runs at request time,
  stays out of the static shell and accepts no custom handler.
- `export const instant` (16.3; `unstable_instant` in 16.2) asks dev/build to
  validate instant navigation into a segment. `instant = false` permits a
  blocking route; it does not clear synchronous-IO errors.

For whole-app adoption or instant-navigation work, Next.js publishes workflow
skills (`next-cache-components-adoption`, `next-cache-components-optimizer`)
in `vercel/next.js/skills`; the bundled migration guide covers the same steps.

## Shape of one route

`app/posts/page.tsx`, checked against next 16.3.8 with `cacheComponents: true`
(`tsc --noEmit`, `next build`, the action under `next start`). `@/lib/*` is
project code.

```tsx
import { Suspense } from 'react'
import { cookies } from 'next/headers'
import { cacheLife, cacheTag, updateTag } from 'next/cache'
import { insertPost, listPosts } from '@/lib/posts' // project code
import { requireEditor } from '@/lib/auth' // throws unless the session may edit

async function getPosts() {
  'use cache' // shared entry: no cookies/headers/searchParams inside
  cacheLife('hours')
  cacheTag('posts')
  return listPosts()
}

async function Theme() {
  const theme = (await cookies()).get('theme')?.value // request-time, outside the cache
  return <p>Theme: {theme ?? 'system'}</p>
}

async function addPost(formData: FormData) {
  'use server'
  await requireEditor()
  const title = String(formData.get('title') ?? '').trim()
  if (!title) return
  await insertPost(title)
  updateTag('posts') // Server Actions only; the next read waits for fresh data
}

export default async function Page() {
  const posts = await getPosts() // cached, so it can be part of the static shell
  return (
    <>
      <ul>{posts.map((p) => <li key={p.id}>{p.title}</li>)}</ul>
      <Suspense fallback={<p>Theme: …</p>}><Theme /></Suspense>
      <form action={addPost}><input name="title" /><button>Add</button></form>
    </>
  )
}
```

## Decide the boundary

- Cache reusable results when the product's freshness and data policy permit.
  Static content needs no directive just to be static.
- A plain `use cache` scope cannot read cookies, headers, searchParams or call
  `connection()`, including indirectly through helpers. Read those outside
  and pass authorized, serializable values.
  Account/tenant IDs must participate in the cache key when output depends on them.
  On a dynamically rendered route, the `next-request-in-use-cache` error can
  pass `next build` and surface only under `next start`.
- Keep uncached I/O and request-only content below appropriate Suspense
  boundaries. Suspense supplies fallback UI; it does not itself make synchronous
  work dynamic.
- Evaluate private/remote variants against installed docs and deployment
  handlers. Private caching is not a compliance guarantee; remote caching is not
  a consistency protocol.

## Define freshness and invalidation

Choose lifetimes from actual acceptable staleness. Named profiles can be
overridden by the project; read its config before assuming a duration.

Use tags when invalidation must reach the same entity across routes, path
invalidation for route-specific output, or expiry where that meets the contract.
Authenticate, authorize and validate before mutations. Invalidate only affected
cached data:

- `updateTag`: immediate expiry/read-your-writes, Server Actions only.
- `revalidateTag(tag, 'max')`: stale-while-revalidate on a later visit.
- `revalidateTag(tag, { expire: 0 })`: immediate expiry where a webhook/Route
  Handler needs it. The one-argument form is deprecated.

These tag APIs can also apply to tagged fetch data; their availability does not
by itself mean Cache Components is enabled.

## Read for the problem

- [API boundaries](REFERENCE.md): keys, serialization, lifetimes, handlers and route APIs.
- [Composition](PATTERNS.md): tenant isolation, nested caches, pass-through and dynamic params.
- [Troubleshooting](TROUBLESHOOTING.md): diagnose blocking, stale or inconsistent output.

Run the production build, then exercise cold/direct navigation, client
navigation, the relevant mutation and subsequent read under `next start`.
Check tenant isolation and multi-instance invalidation when applicable.
A passing build cannot establish those behaviors.
