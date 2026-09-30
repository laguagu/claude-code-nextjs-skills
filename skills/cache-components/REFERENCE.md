# Cache API boundaries

Use installed Next.js docs for signatures, profile values and feature flags.
The upstream Next-skills collection is archived; this file is a focused guide,
not a replacement API reference.

## Keys and serialization

`use cache` functions/components must be async with the directive in the
directive prologue. Cache identity includes function/build identity,
serializable inputs and captured outer variables. Do not assume a global,
unkeyed tenant or user value is safe.

Argument and return serialization differ. Dates, Maps and Sets are supported
in documented forms; arbitrary class instances and URL objects are not.
Non-serializable children or Server Actions may pass through unchanged, without
being read/invoked inside the cached scope. See
[use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache).

Cached functions have an isolated scope. Request storage and outer
`React.cache` deduplication are not a reliable cross-boundary dependency.
Resolve request-dependent promises outside the cached function and pass values.

## Lifetimes

`stale` governs client freshness, `revalidate` the background-refresh window,
and `expire` when a later read must wait for new content. When both are set,
`expire` must exceed `revalidate`. Omitted values inherit the default profile.

Named built-ins can be overridden. Short lifetimes can exclude content from
prerenders or the App Shell; read the installed
[cacheLife reference](https://nextjs.org/docs/app/api-reference/functions/cacheLife)
rather than equating every cached component with static output.

Inner cache lifetimes/tags affect surrounding cached output. Define an outer
lifetime when it should be tighter; verify the resulting refresh behavior.

## Invalidation

`updateTag` expires a tag for read-your-writes and is restricted to Server
Actions. `revalidateTag` supports profiles or an `expire` object; its behavior
depends on that second argument, so it is not uniformly lazy.
`revalidatePath` targets a route and does not replace an entity tag across
unrelated pages. Refreshing a client tree alone does not invalidate persistent
data caches.

Read [updateTag](https://nextjs.org/docs/app/api-reference/functions/updateTag),
[revalidateTag](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)
and [revalidatePath](https://nextjs.org/docs/app/api-reference/functions/revalidatePath)
for the call context and client-cache effects in the installed version.

## Storage and variants

Default runtime storage is per-instance memory unless a handler changes it;
serverless memory is ephemeral, but warm reuse can occur. Do not assume every
invocation is cold or that every host persists cache entries.

`use cache: remote` selects a remote handler with network/storage costs and
deployment-specific guarantees. Configure the real handler; a directive alone
does not install a backing store.

`use cache: private` permits request API access with request/client-scoped
reuse, rather than cross-request shared server storage. Check current feature
support, retention and preview behavior. No variant establishes privacy policy
by itself.

## Routing and runtime

Cache Components changes which segment configuration and runtime options are
supported. Do not mix legacy `dynamic`/`revalidate`/`fetchCache` policies
into an enabled app without checking the migration guide.

GET handlers may prerender when their work permits it; their response and helper
caching are separate decisions. Do not put `use cache` directly in the handler
where unsupported; use an eligible helper. Non-GET execution is request-time,
but reusable read helpers can still have their own cache policy.

`generateStaticParams` and unknown params affect shell composition. Verify
partial/unknown routes and the installed empty-array behavior. For
non-deterministic work, use the documented `io` or request-time boundary where
supported; do not freeze a per-request value accidentally.

[Official caching guide](https://nextjs.org/docs/app/getting-started/caching)
routes to private/remote directives, handlers, ISR and instant navigation.
