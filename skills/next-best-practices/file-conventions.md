# Routing conventions

Use the [installed project-structure guide](https://nextjs.org/docs/app/getting-started/project-structure)
for special files and segment syntax.

Route groups organize layouts without entering the URL; they do not enforce
authentication. Private folders exclude routing. Layouts preserve shared
state, while templates remount their subtree.

Parallel route slots and interceptors match route segments, not raw filesystem
depth. Direct URL visits can render a different path from client navigation;
read [parallel-routes.md](parallel-routes.md) when introducing a modal.

Next.js 16 renamed Middleware to Proxy. `proxy.ts` sits alongside app/pages
(including inside `src`) and runs Node.js; do not set a `runtime` option
there. Existing Edge middleware needs its own supported migration path.
The named export becomes `proxy` (a default export also works), and
`skipMiddlewareUrlNormalize` becomes `skipProxyUrlNormalize`.

Scope the matcher so static/image/public traffic is handled deliberately.
Proxy is suitable for routing/optimistic checks; keep authoritative data
authorization at the actual access. Read the installed
[Proxy reference](https://nextjs.org/docs/app/api-reference/file-conventions/proxy)
before changing request behavior.
