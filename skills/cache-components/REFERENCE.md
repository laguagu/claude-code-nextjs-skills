# Cache API boundaries

Use installed Next.js docs for signatures, profile values and feature flags.
The upstream Next-skills collection is archived; this file is a focused guide,
not a replacement API reference.

## Keys and serialization

`use cache` functions/components must be async with the directive in the
directive prologue. Cache identity includes function/build identity,
serializable inputs and captured outer variables. A configured `deploymentId`
replaces the build ID in this key; changing that identity invalidates entries.
Keys and tags are plain text, including in remote storage: use stable IDs,
not tokens, passwords or raw emails. A file-level directive caches every
exported function, which must then be async; caching a page/layout does not
cache its passed-through `children`.

Argument and return serialization differ. Primitives, plain objects, arrays,
Dates, Maps, Sets, typed arrays and ArrayBuffers are supported; returns also
support JSX. Class instances, URL objects, symbols and ordinary functions are not.
Non-serializable children or Server Actions may pass through unchanged, without
being read/invoked inside the cached scope. See
[use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache).

Cached functions have an isolated scope with their own `React.cache` store;
values stored by the outer request's `React.cache` are invisible inside.
Resolve request-dependent promises outside the cached function and pass values.

## Lifetimes

`stale` governs client freshness, `revalidate` the background-refresh window,
and `expire` when a later read must wait for new content. When both are set,
`expire` must exceed `revalidate`. Omitted values inherit the default profile.
The built-in `default` is stale 5 minutes, revalidate 15 minutes and no expiry;
the client router enforces a minimum stale time of 30 seconds.

Named built-ins can be overridden. Short lifetimes can exclude content from
prerenders or the App Shell; read the installed
[cacheLife reference](https://nextjs.org/docs/app/api-reference/functions/cacheLife)
rather than equating every cached component with static output.

An explicit outer `cacheLife` takes precedence over inner lifetimes, whether
longer or shorter. Without one, shorter inner lifetimes can lower the outer
default. A short-lived inner cache inside an outer `use cache` without its own
`cacheLife` throws during prerendering; give the outer scope an explicit lifetime.
Inner tags propagate to the outer entry, but a time-based inner refresh does
not replace output already embedded in the outer entry.

## Invalidation

`updateTag` expires a tag for read-your-writes and is restricted to Server
Actions. `revalidateTag` supports profiles or an `expire` object; its behavior
depends on that second argument, so it is not uniformly lazy. Only the profile's
`expire` is read. The deprecated one-argument form behaves like `{ expire: 0 }`.
`revalidatePath` targets a route and does not replace an entity tag across
unrelated pages. Refreshing a client tree alone does not invalidate persistent
data caches. A dynamic route pattern requires its `'page'`/`'layout'` argument;
with rewrites, pass the destination route path.

Tags are case-sensitive. A `cacheTag()` call accepts at most 128 tags of at
most 256 characters; excess or oversized tags are dropped with a warning.
Invalidating a tag that was never assigned has no effect.

Read [updateTag](https://nextjs.org/docs/app/api-reference/functions/updateTag),
[revalidateTag](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)
and [revalidatePath](https://nextjs.org/docs/app/api-reference/functions/revalidatePath)
for the call context and client-cache effects in the installed version.

## Storage and variants

Default runtime storage is per-instance memory unless a handler changes it;
serverless memory is ephemeral, but warm reuse can occur. Do not assume every
invocation is cold or that every host persists cache entries.

`use cache: remote` selects `cacheHandlers.remote`; absent host/project
configuration, both `default` and `remote` use an in-memory LRU. Configure the
real backing store and account for its network/storage costs; a directive alone
does not install one.

`use cache: private` permits request API access with request/client-scoped
reuse, rather than cross-request shared server storage. It can read cookies,
headers and searchParams, but not `connection()`, runs at request time and
accepts no custom handler. Check current feature support, retention and preview
behavior. No variant establishes privacy policy by itself.

Draft Mode is an exception to the request-API restriction: a cached scope can
read `(await draftMode()).isEnabled`. It re-executes without storing results;
`enable()`/`disable()` still cannot run inside the cached scope.

## Routing and runtime

Cache Components changes which segment configuration and runtime options are
supported. Do not mix legacy `dynamic`/`revalidate`/`fetchCache` policies
into an enabled app without checking the migration guide.

GET handlers may prerender when their work permits it; their response and helper
caching are separate decisions. `use cache` cannot go on the `GET` export or in
its body; call a cached helper. A prerender bail-out throws, so an existing
`try/catch` can catch/log it as build noise. Non-GET execution is request-time,
but reusable read helpers can still have their own cache policy.

`generateMetadata`/`generateViewport` reading runtime or uncached data errors
when the rest of the page is otherwise prerenderable. Cache reusable external
data; for intentionally runtime-dependent metadata, use the migration guide's
Suspense-wrapped dynamic marker. Metadata caches need their own loader/tag coverage.

`generateStaticParams` and unknown params affect shell composition. Verify
partial/unknown routes and the installed empty-array behavior. For
non-deterministic work, use the documented `io` or request-time boundary where
supported; do not freeze a per-request value accidentally.

[Official caching guide](https://nextjs.org/docs/app/getting-started/caching)
routes to private/remote directives, handlers, ISR and instant navigation.
