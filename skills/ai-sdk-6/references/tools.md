# AI SDK 6 tool contracts

Define typed input with `inputSchema`; keep authorization in `execute` and
server policy. Tool descriptions and model instructions cannot authorize an
operation. A tool without `execute` can be fulfilled by the client or an
external executor; it is not automatically a server action.

V6 manual approval uses tool-level `needsApproval` and the UI's
`addToolApprovalResponse`. Do not replace it with SDK 7's `toolApproval`.
Browser-round-tripped approvals can be forged; late 6.0.x accepts
`experimental_toolApprovalSecret` (HMAC) on core functions and
`ToolLoopAgent`, so check the installed types. Approval does not replace
tenant/role checks or idempotency.

Render the installed union, including `input-streaming`, `input-available`,
`approval-requested`, `approval-responded`, `output-available`,
`output-denied` and `output-error`. Typed parts use `tool-{name}`; runtime
schemas use dynamic tool parts. Partial input is not completed input.

Client tools return results with `addToolOutput` (not deprecated
`addToolResult`). Continue with `useChat({ sendAutomaticallyWhen:
lastAssistantMessageIsCompleteWithToolCalls })` or
`lastAssistantMessageIsCompleteWithApprovalResponses`; avoid a custom resubmit
loop. Provider-executed tools have provider-owned execution and permission
semantics.

See `docs/03-ai-sdk-core/15-tools-and-tool-calling.mdx`,
`docs/04-ai-sdk-ui/03-chatbot-tool-usage.mdx` or the
[v6 tool calling guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/15-tools-and-tool-calling.mdx).
