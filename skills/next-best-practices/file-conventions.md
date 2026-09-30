# Routing conventions

Use `01-getting-started/02-project-structure.md` for special files and
segment syntax.

Route groups organize layouts without entering the URL; they do not enforce
authentication. Private folders exclude routing. Layouts preserve shared
state, while templates remount their subtree.

Parallel route slots and interceptors match route segments, not raw filesystem
depth. Direct URL visits can render a different path from client navigation;
read [parallel-routes.md](parallel-routes.md) when introducing a modal.

Next.js 16 renamed Middleware to Proxy: `proxy.ts` with
`export function proxy`, beside app/pages (inside `src` when used). It runs
Node.js and setting `runtime` there throws. Only the deprecated `middleware.ts`
still runs Edge. `npx @next/codemod@canary middleware-to-proxy .` renames file
and export; config flags follow (`skipMiddlewareUrlNormalize` →
`skipProxyUrlNormalize`).

Without a `matcher`, Proxy runs on every request, including `_next/static`,
`_next/image` and `public/` files; exclude them deliberately. Proxy is suitable
for routing/optimistic checks; keep authoritative authorization at the data
access. Read `03-api-reference/03-file-conventions/proxy.md`.
