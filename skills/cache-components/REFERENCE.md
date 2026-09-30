# Cache API boundaries

Doc paths are relative to `node_modules/next/dist/docs/01-app/` (see SKILL.md
for the web fallback). Signatures: `node_modules/next/cache.d.ts`.

## Keys and serialization

`use cache` functions/components must be async, with the directive first in the
body or file. A file-level directive caches every export, including
`generateMetadata`/`generateStaticParams`, which must then be async; in a
`page`/`layout` it caches only that segment, not its `children`.

The key is build ID (or `deploymentId`) + function ID + serialized arguments +
captured outer variables. Keys and `cacheTag` values are stored in plain text:
key on stable IDs, never tokens, passwords or raw emails.

Arguments and returns: primitives, plain objects, arrays, Date, Map, Set,
typed arrays. Not class instances, URL objects, symbols or functions.
`children` and Server Actions may pass through if never read or invoked inside.
Source: `03-api-reference/01-directives/use-cache.md`.

Each cached scope has its own `React.cache` store, so outer request
deduplication and values set outside are invisible inside. Resolve
request-dependent promises outside and pass values.

## Lifetimes

`stale` is client-router freshness (minimum 30 s enforced), `revalidate` the
background-refresh window, `expire` when a later read must wait. `expire` must
exceed `revalidate`; omitted fields inherit `default` (stale 5 min, revalidate
15 min, expire never). Built-in names can be redefined in `next.config.*`.

Prerender thresholds (`03-api-reference/04-functions/cacheLife.md`):

| Profile value | Result |
| --- | --- |
| `revalidate: 0` or `expire` < 5 min | Dynamic hole, resolved per request; needs Suspense |
| `stale` < 30 s | Excluded from prerenders |
| 30 s ≤ `stale` < 5 min | Prerendered, but not in the App Shell |

Of the presets only `seconds` crosses a threshold.

Nesting: an explicit outer `cacheLife` always wins, longer or shorter than
inner ones. Without one, the outer uses `default`, and a shorter inner lifetime
lowers it. A short-lived inner cache inside an outer `use cache` without
`cacheLife` is a prerender error, even from a dependency.

## Invalidation

- `updateTag(tag)`: Server Actions only; next read waits for fresh data.
- `revalidateTag(tag, profile)`: Server Actions and Route Handlers; only the
  profile's `expire` is read. `'max'` serves stale while refreshing;
  `{ expire: 0 }` blocks the next read. Refresh happens per visited page, not
  at the call.
- `revalidatePath('/p/1')` or `revalidatePath('/p/[slug]', 'page')`: the type
  is required for a pattern; with rewrites pass the destination. Route-scoped:
  it does not reach the same entity on unrelated routes.
- Tags are case-sensitive, max 256 chars; one `cacheTag` call keeps at most 128.
  Oversized tags are dropped with a warning, so revalidating them does nothing.

Any of these, or `refresh()`, called from a Server Action clears the whole
client router cache. Draft Mode re-executes cached scopes and saves nothing;
`draftMode().isEnabled` is readable inside `use cache`.

## Storage and variants

| Directive | Server storage | Request APIs inside |
| --- | --- | --- |
| `'use cache'` | `cacheHandlers.default`; in-memory LRU per instance | No |
| `'use cache: remote'` | `cacheHandlers.remote`; the same in-memory LRU unless the host or project configures one | No |
| `'use cache: private'` | None; per-request dedupe plus browser memory for `stale` | `cookies`, `headers`, `searchParams` (not `connection`) |

Serverless memory rarely survives between requests. No directive survives a
deploy. Use remote for rate-limited or slow upstreams and low-cardinality keys;
per-user or per-filter keys waste it. Private runs at request time, is excluded
from the static shell and cannot use a custom handler; `cacheLife({ stale:
Infinity })` keeps a dedupe-only private function from lowering route stale time.
Sources: `use-cache-remote.md`, `use-cache-private.md` in
`03-api-reference/01-directives/`, and
`03-api-reference/05-config/01-next-config-js/cacheHandlers.md`.

## Routes, params and metadata

- GET Route Handlers prerender unless they read the request, uncached data or
  non-deterministic values. `use cache` cannot go on the `GET` export or in its
  body; call a cached helper. The bail-out throws, so an existing `try/catch`
  catches and logs it as build noise. Non-GET methods run per request.
- `generateMetadata`/`generateViewport` follow component rules: `use cache`
  for external data; runtime data there errors unless the page is otherwise
  dynamic. Their entries are separate from the page's, so reuse its tags.
- Unlisted params are served from a shell and streamed; sending that App Shell
  before a full server render needs 16.3+, and `partialPrefetching: true`
  upgrades it after the first visit. Deleting `generateStaticParams` makes the
  route render on every request, even with cached data. See
  `02-guides/incremental-static-regeneration-cache-components.md`.
