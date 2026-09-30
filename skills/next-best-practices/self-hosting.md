# Self-hosted runtime contracts

Use the installed [self-hosting guide](https://nextjs.org/docs/app/guides/self-hosting)
and the project's adapter/deploy scripts. Standalone output is useful for
containers but is not required for every host.

Standalone tracing does not copy `public` or `.next/static` automatically.
Serve/copy them at the correct app/workspace path and verify the runtime has
needed native dependencies. Monorepo tracing roots can change emitted paths.

Build-time `NEXT_PUBLIC_*` values are bundled; they cannot become runtime
configuration merely by changing the container environment. Read server-only
configuration at runtime where supported.

Multiple instances need deliberate cache storage and invalidation coordination.
The legacy ISR `cacheHandler` and Cache Components `cacheHandlers` are different
contracts. Use a maintained adapter or implement against current types; a toy
Redis/S3 get/set example omits important tags/expiry semantics.
For Cache Components, `updateTags()` writes shared invalidation events and
`refreshTags()` synchronizes them before requests. A shared entry store alone
does not synchronize each instance's tag state.

Coordinate build IDs, action encryption keys and deployment skew where the app
needs it. Preserve streaming through the real proxy/load balancer. Readiness
checks should fit the service's dependencies.

Verify the actual runtime artifact, assets, a write followed by read and
cross-instance behavior where applicable. Local `next dev` cannot establish
deployment readiness.
