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

Test two identities with overlapping resource IDs. Private caching is an
alternative when supported and suitable; it does not replace execution-time
authorization or prevent server logging.

## Nested caches and pass-through

Use nested cached reads when they have distinct lifetimes or consumers.
Do not depend on outer request `React.cache` storage inside a `use cache`
scope. If the outer output embeds stale data, refreshing only its inner source
may be insufficient; verify dependency/tag propagation.

Pass dynamic children or Server Actions through a cached wrapper unchanged.
Do not inspect children or invoke the action there; pass-through values do not
become ordinary cache-key inputs.

## Dynamic params and navigation

Read unknown params deeper in the tree when that preserves a useful shared
shell. Resolve request-dependent values before invoking cached functions; a
promise awaiting a nonexistent build-time request can stall prerendering.

For `generateStaticParams`, use real representative values and check both
listed and unlisted paths. Shell/partial-param behavior varies with version.
Use the installed instant-navigation diagnostics where available.

## Deployment

Choose the actual backing store and invalidation mechanism for the deployment.
Multiple instances need coordinated data/cache behavior where shared freshness
is required. Do not implement a generic Redis/S3 handler from a tutorial: use
the installed Next.js handler contract and a maintained adapter or a tested
project implementation.

Read the [caching guide](https://nextjs.org/docs/app/getting-started/caching)
and [self-hosting guide](https://nextjs.org/docs/app/guides/self-hosting) for
matching implementations.
