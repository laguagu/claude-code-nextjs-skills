# Runtime selection

Node.js is the default and the target for new code. In Next.js 16
`export const runtime = 'edge'` is deprecated: remove it rather than adding it.
Proxy always runs Node.js, Cache Components requires Node.js, and Edge ISR is
unsupported. Keep an existing Edge route only when the deployment requires it,
and plan its removal.

Runtime location is hosting-specific; an Edge label alone does not prove lower
latency. Read `03-api-reference/03-file-conventions/02-route-segment-config/runtime.md`
and the deployment adapter's current support.
