# Cache diagnostics

Reproduce with the installed version and actual caching configuration. Dev
errors and insights name the component and print fix options (`[stream]`
Suspense, `[cache]` `use cache`, `[block]` `instant = false`) in the overlay,
terminal and `next build` output; the slug links to `nextjs.org/docs/messages/`.

| Message (16.3 slug) | Cause | Fix |
| --- | --- | --- |
| `blocking-prerender-dynamic`: uncached data during prerendering | `fetch`/DB/`connection()` outside Suspense, or a boundary too high | Suspense at the read, or `use cache` |
| `blocking-prerender-runtime` | `cookies()`/`headers()`/`params`/`searchParams` awaited outside Suspense | Move the read into a Suspense-wrapped child |
| `blocking-prerender-client-hook` | `useSearchParams`, or `usePathname`/`useParams`/`useSelectedLayoutSegment(s)` under unknown params | Suspense around the smallest reading leaf |
| `blocking-prerender-random`, `-current-time`, `-crypto` | Sync non-deterministic value during prerender; `instant = false` does not clear it | `await io()` (16.3+) or `connection()` first, `use cache`, or client-only |
| `next-request-in-use-cache` | Request API inside a cached scope or its helpers; may appear only under `next start` | Read outside and pass the value, or `use cache: private` |
| Filling a cache during prerender timed out (50 s) | Cached scope awaits a request promise passed as a prop, captured, or read from a shared `Map` | Await outside; pass the resolved value |
| `empty-generate-static-params` | `generateStaticParams` returned `[]` | Return at least one real param |
| `Route segment config "dynamicParams" is not compatible` | Legacy segment config | Delete it; `notFound()` for unknown params |
| Short-lived nested cache error | Inner `expire` < 5 min or `revalidate: 0` inside an outer `use cache` without `cacheLife` | Explicit outer `cacheLife` |
| `blocking-prerender-metadata-runtime` | `generateMetadata` reads runtime or uncached data | `use cache` for external data; for real runtime data, render a Suspense-wrapped component that awaits `connection()` |

Older 16.x releases print other slugs; follow the printed link.

| Symptom | Inspect before changing policy |
| --- | --- |
| Repeated reads | Key inputs, handler lifetime, instance/deploy identity (keys include the build ID) |
| Stale after mutation | Write completion, tag/path coverage, invalidation profile, client `stale` |
| Different values across instances | Shared handler and `refreshTags()`; one-process tests cannot prove it |
| Cross-account output | Identity/filter in the key, module-level mutable state, permission changes |
| Metadata or sitemap stale | Its own loader and tags, not merely the page's |

A timeout is not proof of user-specific data; do not remove caching or add
fake build data to hide it. Do not catch framework bail-outs in broad
`try/catch`. `NEXT_PRIVATE_DEBUG_CACHE=1 next start` logs cache activity; in dev,
logs from cached scopes carry a `Cache` prefix. `next build --debug-prerender`
adds server source maps and continues past the first failure; never deploy it.
Instrument the loader without logging sensitive arguments, then verify direct
load, client navigation, listed/unlisted params and a second identity.
