# Cache composition decisions

Doc paths are relative to `node_modules/next/dist/docs/01-app/`.

## Shell and params

Keep stable navigation/content outside the parts that wait on request data, and
make each fallback a meaningful placeholder: its scope sets what ships in the
shell. A Suspense boundary high in a layout still blocks navigation into that
segment; push it down to the data read.

Do not await `params` above the boundary, even for params
`generateStaticParams` lists: that ties the layout's shell to one URL. Pass the
promise into the Suspense-wrapped child. Client URL hooks follow the same rule
(see `02-guides/instant-navigation.md`).

A root-layout `<html lang|dir|data-theme>` read from a cookie makes the whole
tree request-bound. Set it with an inline `<head>` script instead
(`02-guides/preventing-flash-before-hydration.md`).

In 16.3 dev validates every page for instant navigation by default.
`export const instant = false` lets a segment block and opts it out of
static-shell validation; use it to adopt incrementally, not to silence a route
permanently. It does not clear synchronous-value errors.

## Mutations and related reads

Authorize and validate first, commit the mutation, then invalidate the affected
entity/collection or path. Choose `updateTag` versus `revalidateTag` from the
product contract: a legal or availability change may need immediate freshness
even when an administrator made it. Metadata, sitemaps and related views share
freshness only if they share loaders or tags.

## Tenant and user data

Authenticate outside a shared cache boundary and pass the authorized identity
plus every output-relevant filter as arguments. Keep the per-user cached
function unexported and resolve the user inside the exported getter, so no
caller can pass another user's ID. Keys and tags are plain text; never key on
tokens or emails. Keep permission changes, account deletion and retention in
the invalidation design. Test two identities with overlapping resource IDs.
Walkthrough: `02-guides/authentication-with-cache-components.md`.

## Nested caches and pass-through

Nest cached reads when they have distinct lifetimes or consumers, and give the
outer scope an explicit `cacheLife`. Inner tags propagate to the outer entry,
so tag invalidation reaches both; time-based refresh does not, since the outer
entry keeps the embedded inner output until its own lifetime ends.

A cached wrapper may pass dynamic `children` or a Server Action through
unchanged; reading children or invoking the action inside breaks the contract.

## Navigation state

With `cacheComponents`, Next.js hides routes you navigate away from with React
`<Activity>` instead of unmounting them: `useState`, form values and open dropdowns survive
back navigation, and effects re-run. Reset explicitly where the UI assumed
unmount (`02-guides/preserving-ui-state.md`).

## Deployment

Choose the actual backing store and invalidation path for the deployment.
Multiple instances need a shared `cacheHandlers` store and tag sync through the
handler's `refreshTags()`; one-process tests cannot show that. Every deploy
starts with empty `use cache` entries. Use a maintained adapter or the
installed handler contract
(`03-api-reference/05-config/01-next-config-js/cacheHandlers.md`,
`02-guides/how-revalidation-works.md`) rather than a tutorial Redis/S3 handler.
