# Framework API lookup

Find the needed function in the installed `next/dist/docs/` API reference or
[official function index](https://nextjs.org/docs/app/api-reference/functions).
Avoid re-creating a static catalog of signatures and defaults.

For App Router navigation, use `next/navigation` hooks and internal links that
fit the route. Check suspense behavior for URL-dependent hooks in the actual
rendering mode.

Request APIs and params are async in current versions. Server navigation helpers
throw framework control-flow signals; a broad catch must preserve them.
Generated metadata/image/sitemap handlers have their own parameter contracts.

`after` can defer work until the response lifecycle, but hosting duration and
failure limits still apply; it is not a durable queue.
`refresh()` from `next/cache` is Server Action-only and refreshes the client
router; it does not invalidate server data caches.
