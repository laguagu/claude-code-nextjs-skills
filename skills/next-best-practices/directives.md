# Directive boundaries

Use `use client` at module boundaries that require browser interactivity.
It affects imported runtime code, not the origin of children passed through
a server parent.

`use server` marks callable Server Functions; it is not the marker for every
Server Component. Treat exported actions as endpoints requiring their own
authorization.

`use cache` (and `use cache: private`/`remote`) is Next.js caching and
requires `cacheComponents: true`; see the `cache-components` skill.

Read `03-api-reference/01-directives/` (`use-client.md`, `use-server.md`,
`use-cache.md`).
