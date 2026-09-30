# Directive boundaries

Use `use client` at module boundaries that require browser interactivity.
It affects imported runtime code, not the origin of children passed through
a server parent.

`use server` marks callable Server Functions; it is not the marker for every
Server Component. Treat exported actions as endpoints requiring their own
authorization.

`use cache` is Next.js caching, with its own async/serialization and request
API constraints. Confirm Cache Components configuration before introducing it.

Read [React use client](https://react.dev/reference/rsc/use-client),
[use server](https://react.dev/reference/rsc/use-server) and
[Next.js use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache).
