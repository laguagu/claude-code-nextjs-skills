---
name: cache-components
description: "Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). Use when implementing 'use cache' directive, configuring cache lifetimes with cacheLife(), tagging cached data with cacheTag(), invalidating caches with updateTag()/revalidateTag(), optimizing static vs dynamic content boundaries, instant navigation validation, 'use cache: private', pass-through/interleaving patterns, GET Route Handler caching, debugging cache issues, and reviewing Cache Component implementations."
metadata:
  version: "1.0"
---

# Cache Components

Keep the project's caching mode unless migration is requested. Confirm the
installed Next.js version and `cacheComponents` configuration before applying
these patterns. Read the relevant `node_modules/next/dist/docs/` guide first;
fallback to [official caching docs](https://nextjs.org/docs/app/getting-started/caching).

The goal is a useful prerendered shell with freshness and authorization rules
that remain correct after mutations, deploys and client navigation.

## Decide the boundary

- Cache reusable results when the product's freshness and data policy permit.
  Static content needs no directive just to be static.
- A plain `use cache` scope cannot read request APIs, including indirectly
  through helpers. Read those outside and pass authorized, serializable values.
  Account/tenant IDs must participate in the cache key when output depends on them.
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

Run the production build and exercise cold/direct navigation, the relevant
mutation and subsequent read. Check tenant isolation and multi-instance
invalidation when applicable. A passing build cannot establish those behaviors.
