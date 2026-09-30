# Cache diagnostics

Reproduce with the installed version and actual caching configuration.
Use Next.js development diagnostics/MCP when available, then verify with the
production build and runtime. Build success does not prove freshness,
authorization or runtime-only helper paths.

| Symptom | Inspect before changing policy |
| --- | --- |
| Blocking/dynamic access | Where uncached I/O, unknown params or request APIs are awaited relative to Suspense |
| Request data inside cache | The whole helper call stack, not only the visible cached function |
| Build stalls/timeouts | Slow/unavailable build services, request-dependent promises, isolated request storage |
| Repeated reads | Key inputs, handler lifetime, process/deploy identity and deliberate bypasses |
| Stale after mutation | Write completion, tag/path coverage, invalidation profile and client freshness |
| Different values across instances | Backing store and cross-instance invalidation; one-process tests cannot prove it |
| Cross-account output | Authorized identity/filter keying, global mutable state and policy changes |
| Metadata or sitemap stale | Its own data loader and refresh path, not merely the page's cache |

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
