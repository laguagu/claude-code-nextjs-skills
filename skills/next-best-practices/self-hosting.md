# Self-hosted runtime contracts

Use `02-guides/self-hosting.md` and the project's adapter/deploy scripts.
Standalone output is useful for containers but is not required for every host.

Standalone tracing does not copy `public` or `.next/static` automatically.
Serve/copy them at the correct app/workspace path and verify the runtime has
needed native dependencies. In a monorepo set `outputFileTracingRoot`, which
changes emitted paths.

Build-time `NEXT_PUBLIC_*` values are bundled; they cannot become runtime
configuration merely by changing the container environment. Read server-only
configuration at runtime where supported.

The legacy ISR `cacheHandler` and Cache Components `cacheHandlers` are different
contracts. Use a maintained adapter or implement against current types; a toy
Redis/S3 get/set example omits important tags/expiry semantics.

Across instances and rolling deploys set `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`
(base64 AES key) and `deploymentId` (skew protection; it overrides
`generateBuildId`). Tag invalidation needs the handler's `refreshTags()` backed
by shared storage. Preserve streaming through the real proxy/load balancer;
without it the static shell and dynamic parts arrive together. Readiness
checks should fit the service's dependencies.

Verify the actual runtime artifact, assets, a write followed by read and
cross-instance behavior where applicable. Local `next dev` cannot establish
deployment readiness.
