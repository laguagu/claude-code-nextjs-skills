---
title: Tools in AI SDK 7
description: Tool schemas, context, approvals, MCP Apps, and sandbox handles.
---

# Tool execution and approval

Use `inputSchema` and keep server authorization in the executor. Shared loop
state uses `runtimeContext`; each `toolsContext` entry is validated by that
tool's `contextSchema`. Context is not model-visible by default.

ToolLoopAgent/core generation use `toolApproval`; rules may approve, deny,
request manual approval or be not applicable. WorkflowAgent instead uses
tool-level `needsApproval` for durable suspension. Subagent, provider-executed
and harness built-in tools have separate constraints.

Browser history can fabricate an approval response. Bind sensitive decisions to
server-issued state. Where the installed core API supports
`experimental_toolApprovalSecret`, verify its signed approval contract;
do not assume all agent classes accept it. Recheck authorization at execution.

Update context through supported preparation hooks, rather than mutating
shared tool state. Workflow context must serialize; a live
`experimental_sandbox` handle belongs to execution, not persisted context.

MCP Apps use an experimental React renderer and app-only resource/tool metadata.
Validate server identity/resource loading and distinguish app-only tools from
model-visible ones.

Read installed package types and
[tool calling docs](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling)
for policy signatures, dynamic tool parts, timeouts and approvals.
