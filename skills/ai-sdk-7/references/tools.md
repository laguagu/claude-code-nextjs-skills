---
title: Tools in AI SDK 7
description: Tool schemas, context, approvals, MCP Apps, and sandbox handles.
---

# Tool execution and approval

Use `inputSchema` and keep server authorization in the executor. Shared loop
state uses `runtimeContext`; each `toolsContext` entry is validated by that
tool's `contextSchema`. Context is not model-visible by default.

ToolLoopAgent/core generation use `toolApproval`: a per-tool map or one
function returning `'not-applicable'` (default; also `undefined`),
`'approved'`, `'denied'` (or `{ type: 'denied', reason }`) or
`'user-approval'`. Tool-level `needsApproval` is deprecated there but still
the WorkflowAgent API. Subagent tools cannot use approval at all;
provider-executed and harness built-in tools follow provider/adapter policy.

Browser history can fabricate an approval response. For sensitive tools set
`experimental_toolApprovalSecret` (string/bytes on core functions and
ToolLoopAgent; env-var reference on WorkflowAgent) so replayed approvals are
HMAC-verified. Recheck authorization at execution.

Update context by returning `runtimeContext`/`toolsContext` from
`prepareStep`, rather than mutating shared tool state. Workflow context must serialize; a live
`experimental_sandbox` handle belongs to execution, not persisted context.

MCP Apps render with `experimental_MCPAppRenderer` (`@ai-sdk/react`) and use
app-only resource/tool metadata. Validate server identity/resource loading and
distinguish app-only tools from model-visible ones. v7 MCP transports reject
redirects by default (`redirect: 'error'`).

Read `docs/03-ai-sdk-core/` (`15-tools-and-tool-calling`,
`17-runtime-and-tool-context`, `17-mcp-apps`), `docs/03-agents/06-tool-approvals.mdx`
or the [tool calling docs](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling)
for policy signatures, dynamic tool parts, timeouts and approvals.
