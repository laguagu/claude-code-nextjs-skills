# Cache composition decisions

## Public shell with request-time work

Keep stable navigation/content outside the parts that wait on request data.
Place meaningful fallbacks around those parts; their scope determines what can
render immediately. A synchronous operation can still run during prerendering
inside Suspense.

Cache the shared read rather than the whole page when personalization or
freshness differs by section. Cache short-lived output only when the resulting
request-time boundary fits the UI.

## Mutations and related reads

Authorize and validate first, commit the mutation, then invalidate the affected
entity/collection or path. Choose immediate freshness versus stale-while-revalidate
from the product contract. Publishing a legal or availability change may require
immediate freshness even if an administrator initiated it.

Use shared loaders/tags for page content, metadata and related views when they
represent the same data. Their caches are not guaranteed to invalidate merely
because they appear on one page.

## Tenant and user data

Authenticate outside a shared cache boundary. Pass the authorized identity and
all output-relevant filters into its key. Keep permission changes, account
deletion and retention requirements in the invalidation design.

For a per-user loader, keep the cached ID-taking function unexported and resolve
the user in the exported getter, so callers cannot supply another user's ID.
See the installed `01-app/02-guides/authentication-with-cache-components.md`.

Test two identities with overlapping resource IDs. Private caching is an
alternative when supported and suitable; it does not replace execution-time
authorization or prevent server logging.

## Nested caches and pass-through

Use nested cached reads when they have distinct lifetimes or consumers.
Do not depend on outer request `React.cache` storage inside a `use cache`
scope. Inner tags propagate to the outer entry; a time-based inner refresh
does not replace the outer entry's embedded output. Set an explicit outer
lifetime when those outputs need a clear refresh contract.

Pass dynamic children or Server Actions through a cached wrapper unchanged.
Do not inspect children or invoke the action there; pass-through values do not
become ordinary cache-key inputs.

## Dynamic params and navigation

Read unknown params deeper in the tree when that preserves a useful shared
shell. Pass the request promise to the Suspense-wrapped child and await it
there, rather than blocking the layout. Resolve request-dependent values
before invoking cached functions; a promise awaiting a nonexistent build-time
request can stall prerendering.

For `generateStaticParams`, use real representative values and check both
listed and unlisted paths. Shell/partial-param behavior varies with version.
Use the installed instant-navigation diagnostics where available.

From 16.3, unlisted params can receive the App Shell before a full server
render; `partialPrefetching: true` supports upgrading that shell after the
first visit. Earlier versions wait for the full render. Read the installed
`01-app/02-guides/incremental-static-regeneration-cache-components.md`.

With Cache Components, Next.js retains recent pages with React `<Activity>`.
Back navigation can restore React state and DOM state, including form drafts
and open dropdowns. Effects clean up when hidden and re-run when shown; reset
transient state explicitly where the UI relied on unmounting. See the
[state-preservation guide](https://nextjs.org/docs/app/guides/preserving-ui-state).

## Deployment

Choose the actual backing store and invalidation mechanism for the deployment.
Multiple instances need coordinated data/cache behavior where shared freshness
is required: custom `cacheHandlers` use `updateTags()` to write invalidations
and `refreshTags()` to synchronize them before requests. `cacheHandler` for
legacy ISR is a different contract. Do not implement a generic Redis/S3 handler
from a tutorial: use
the installed Next.js handler contract and a maintained adapter or a tested
project implementation.

Read the [caching guide](https://nextjs.org/docs/app/getting-started/caching)
and [self-hosting guide](https://nextjs.org/docs/app/guides/self-hosting) for
matching implementations.
