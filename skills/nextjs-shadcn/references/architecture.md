# Next.js integration

Use the project's installed-version docs for API details. This reference covers the boundaries that matter when composing shadcn interfaces.

## Server and Client Components

Default to Server Components for server data and static composition. Put state, event handlers and browser APIs behind a Client Component boundary. Keep that boundary as narrow as practical; providers can wrap larger subtrees.

Only props crossing from Server to Client Components need React-supported serialization. Ordinary client callbacks can pass within a Client subtree. Server Functions are a supported exception to the restriction on ordinary functions crossing the boundary.

Pass Server-rendered content through `children` or other supported slots rather than importing server-only modules into Client Components.

## Routing and layouts

Keep shared navigation and providers in the appropriate layout and route-specific content near its route. Use route groups to organize routes without changing URLs; the name `(protected)` provides no authorization.

Layouts preserve shared state during navigation. Use a template when remounting the subtree is intentional. Prefer `loading.tsx` or granular Suspense boundaries where streaming improves the experience; keep fallbacks proportional to the content.

In current App Router versions, `params` and `searchParams` are promises. Resolve them with `await` in async Server Components or React `use` in an appropriate Client Component. Check the installed version before applying migration patterns.

For request interception in Next.js 16+, `proxy.ts` replaces the middleware convention. Place it alongside `app` or `pages`, including inside `src` when that is the project's layout. Proxy redirects and optimistic checks do not replace authorization in data access or mutations.

## Reads, writes and cache

Prefer Server Components or Route Handlers for reads and Server Actions for mutations. Actions can read, but client action dispatch is not a general parallel query transport.

Authenticate, authorize and validate each mutation. Decide whether data may be shared, cached and refreshed before adding a cache directive.

- `"use cache"`, `cacheTag` and `cacheLife` use Cache Components and require `cacheComponents: true`.
- `updateTag` is restricted to Server Actions and immediately expires a tag for read-your-own-writes. It also works with `fetch` tags and does not itself require Cache Components.
- `revalidateTag(tag, "max")` uses stale-while-revalidate and can also be called from Route Handlers. The one-argument form is deprecated; `{ expire: 0 }` provides immediate expiry when needed there.
- Read request-specific values outside shared cached scopes and pass suitable values as arguments. Never accidentally share a user's private result across users.

Choose request-time APIs and Suspense boundaries according to the installed version's rendering model rather than adding `connection()` to every read.

## Sources

- [Server and Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components)
- [Route groups](https://nextjs.org/docs/app/api-reference/file-conventions/route-groups)
- [Proxy](https://nextjs.org/docs/app/api-reference/file-conventions/proxy)
- [use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache)
- [updateTag](https://nextjs.org/docs/app/api-reference/functions/updateTag)
- [revalidateTag](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)
- [Next.js MCP](https://nextjs.org/docs/app/guides/mcp)
