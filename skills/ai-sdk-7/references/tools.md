---
title: Tools in AI SDK 7
description: Tool schemas, context, approvals, MCP Apps, and sandbox handles.
---

# Tool execution and approval

Use `inputSchema` and keep server authorization in the executor. Shared loop
state uses `runtimeContext`; each `toolsContext` entry is validated by that
tool's `contextSchema`. Context is not model-visible by default.

ToolLoopAgent/core generation use `toolApproval`, per tool or as one callback;
a rule returns `'user-approval'`, `'approved'`, `'denied'` or
`'not-applicable'` (`undefined` means not applicable). Object outcomes can
include `reason` for approved, denied or user-approval; not-applicable cannot.
WorkflowAgent instead uses tool-level `needsApproval` for
durable suspension. Subagent, provider-executed and harness built-in tools
have separate constraints: subagent tools cannot use `toolApproval`.

Browser history can fabricate an approval response. Bind sensitive decisions to
server-issued state. `experimental_toolApprovalSecret` takes string/bytes
on core functions and ToolLoopAgent; WorkflowAgent takes an environment
variable reference (see [agents.md](agents.md)). Verify installed support and
recheck authorization at execution.

Update context through supported preparation hooks, rather than mutating
shared tool state. Workflow context must serialize; a live
`experimental_sandbox` handle belongs to execution, not persisted context.

MCP Apps use `experimental_MCPAppRenderer` from `@ai-sdk/react` and app-only
resource/tool metadata.
Validate server identity/resource loading and distinguish app-only tools from
model-visible ones.

Read installed package types and
[tool calling docs](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling)
for policy signatures, dynamic tool parts, timeouts and approvals.
