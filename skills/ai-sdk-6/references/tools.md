# AI SDK 6 tool contracts

Define typed input with `inputSchema`; keep authorization in `execute` and
server policy. Tool descriptions and model instructions cannot authorize an
operation. A tool without `execute` can be fulfilled by the client or an
external executor; it is not automatically a server action.

V6 manual approval uses tool-level `needsApproval` and the UI's
`addToolApprovalResponse`. Do not replace it with SDK 7's `toolApproval`.
Bind browser-round-tripped approval to trusted server state for sensitive
operations. `experimental_toolApprovalSecret` (HMAC-signed approvals) is
accepted by `generateText`/`streamText` from 6.0.202 and by `ToolLoopAgent`
settings and `prepareCall` from 6.0.272. Before 6.0.202, approved tool calls
replayed from client history ran without schema re-validation or an approval
re-check, so a forged approval executed: treat 6.0.202 as the security floor.
Approval does not replace tenant/role checks or idempotency.

Render the installed union, including `input-streaming`, `input-available`,
`approval-requested`, `approval-responded`, `output-available`,
`output-denied` and `output-error`. Typed parts use `tool-{name}`; runtime
schemas use dynamic tool parts. Partial input is not completed input.

Continue with `sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithToolCalls`
or `...WithApprovalResponses` when all client tool outputs or approvals are
ready; avoid a custom loop that resubmits indefinitely. Client-executed tools
answer from `onToolCall`: check `toolCall.dynamic` first for type narrowing,
and call `addToolOutput({ tool, toolCallId, output })` (or `state:
'output-error'` with `errorText`) without awaiting it there, which can deadlock.
Provider-executed tools have provider-owned execution and permission semantics.

See the installed tool source and
[v6 tool calling guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/15-tools-and-tool-calling.mdx).
