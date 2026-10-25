# Async request APIs

Next.js 16 removes the synchronous fallback retained in 15: `params`,
`searchParams`, `cookies()`, `headers()` and `draftMode()` must be awaited in
async server code, or unwrapped with React `use()` in a synchronous component.
This includes params in Route Handlers, `default` and image/icon generating
routes.

Resolve request-dependent values at the boundary that actually needs them.
Awaiting all params at a high layout level can reduce the reusable shell; with
Cache Components, keep unknown/request-only work under a useful boundary.

Do not pass unresolved request promises into a shared cache function. Do not
mechanically make client components async.

For an authorized migration, start at
[Next.js upgrades](https://nextjs.org/docs/app/guides/upgrading).
