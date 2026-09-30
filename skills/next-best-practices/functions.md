# Framework API lookup

Find the function in `03-api-reference/04-functions/` (one file per API) and
its export in `node_modules/next/*.d.ts`.

For App Router navigation, use `next/navigation` hooks and internal links that
fit the route. Check suspense behavior for URL-dependent hooks in the actual
rendering mode.

Request APIs and params are async in current versions. Server navigation helpers
throw framework control-flow signals; a broad catch must preserve them.
Generated metadata/image/sitemap handlers have their own parameter contracts.

`after` can defer work until the response lifecycle, but hosting duration and
failure limits still apply; it is not a durable queue. `refresh()` from
`next/cache` (Server Actions only) refreshes the client router; it does not
invalidate server caches.
