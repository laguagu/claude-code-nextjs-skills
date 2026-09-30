# Cache diagnostics

Reproduce with the installed version and actual caching configuration.
Use Next.js development diagnostics when available: `next-devtools-mcp` reaches
the dev server's `/_next/mcp` (`get_errors`, `get_logs`, `get_page_metadata`;
`get_compilation_issues`/`compile_route` with Turbopack),
`NEXT_PRIVATE_DEBUG_CACHE=1` logs cache activity, and
`next build --debug-prerender` keeps server source maps (not for deployment).
Then verify with the production build and runtime. Build success does not
prove freshness, authorization or runtime-only helper paths.

| Symptom | Inspect before changing policy |
| --- | --- |
| Blocking/dynamic access | Where uncached I/O, unknown params or request APIs are awaited relative to Suspense |
| `next-request-in-use-cache` | The whole helper call stack, not only the visible cached function; a dynamic route may pass build and fail under `next start`. Read outside and pass resolved values, or use a suitable private cache |
| Build stalls/timeouts | Slow/unavailable build services or a request promise passed/captured into the isolated cached scope; await request values outside |
| Repeated reads | Key inputs, handler lifetime, process/deploy identity and deliberate bypasses |
| Stale after mutation | Write completion, tag/path coverage, invalidation profile and client freshness |
| Different values across instances | Backing store and cross-instance invalidation; one-process tests cannot prove it |
| Cross-account output | Authorized identity/filter keying, global mutable state and policy changes |
| Metadata or sitemap stale | Its own data loader and refresh path, not merely the page's cache |

With Cache Components, `empty-generate-static-params` means the export returned
`[]`; supply at least one real param. A `dynamicParams` compatibility error
requires removing that legacy export and using `notFound()` for rejected
unknown params. A short-lived nested-cache prerender error requires an explicit
outer `cacheLife`, including when the inner read comes from a dependency.

A timeout is not proof of user-specific data. Such data may be cached with
correctly scoped keys when policy permits. Removing caching or adding build-time
fake data can hide the actual fault.

Do not infer every internal cache hit from a route-level response header.
Instrument the relevant loader/handler without logging sensitive arguments.
Measure cold/warm paths and inspect returned content after an actual write.

For request-only work, keep a useful fallback boundary. For short-lived cache
holes, check the installed lifetime thresholds. Avoid broad catch blocks that
swallow framework control-flow exceptions.

Exercise direct load, client navigation, listed/unlisted params and a second
identity as applicable. Check the deployed environment when local lifetime,
storage or proxy behavior differs.

Relevant official references:
[use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache),
[cacheLife](https://nextjs.org/docs/app/api-reference/functions/cacheLife),
[caching](https://nextjs.org/docs/app/getting-started/caching),
[MCP diagnostics](https://nextjs.org/docs/app/guides/mcp).
