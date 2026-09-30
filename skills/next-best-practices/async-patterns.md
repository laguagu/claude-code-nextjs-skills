# Async request APIs

Current App Router params/searchParams and request APIs such as cookies/headers
are asynchronous. Check the installed version for typed route helpers, await
values in async server code, or use React's supported promise consumption where
appropriate.

Resolve request-dependent values at the boundary that actually needs them.
Awaiting all params at a high layout level can reduce the reusable shell; with
Cache Components, keep unknown/request-only work under a useful boundary.

Do not pass unresolved request promises into a shared cache function. Do not
mechanically make client components async.

Use the installed upgrading guide and official codemod for an authorized
migration, then review the actual types/runtime behavior. Start at
[Next.js upgrades](https://nextjs.org/docs/app/guides/upgrading).
