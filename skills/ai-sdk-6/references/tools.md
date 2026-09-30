# AI SDK 6 tool contracts

Define typed input with `inputSchema`; keep authorization in `execute` and
server policy. Tool descriptions and model instructions cannot authorize an
operation. A tool without `execute` can be fulfilled by the client or an
external executor; it is not automatically a server action.

V6 manual approval uses tool-level `needsApproval` and the UI's
`addToolApprovalResponse`. Do not replace it with SDK 7's `toolApproval`.
Bind browser-round-tripped approval to trusted server state for sensitive
operations. Approval does not replace tenant/role checks or idempotency.

Render the installed union, including `input-streaming`, `input-available`,
`approval-requested`, `approval-responded`, `output-available`,
`output-denied` and `output-error`. Typed parts use `tool-{name}`; runtime
schemas use dynamic tool parts. Partial input is not completed input.

Use the documented automatic-send predicates when all client tool outputs or
approvals are ready; avoid a custom loop that resubmits indefinitely.
Provider-executed tools have provider-owned execution and permission semantics.

See the installed tool source and
[v6 tool calling guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/15-tools-and-tool-calling.mdx).
