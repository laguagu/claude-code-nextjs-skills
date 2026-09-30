# Tool approval

Approval suspends a proposed tool operation until an explicit decision. It
complements server authorization; it does not establish a client's identity or
permission to act.

## Version and policy

| | v7 | v6 |
| --- | --- | --- |
| Configure | `toolApproval` on `ToolLoopAgent`, `generateText` or `streamText`: `{ deleteFile: 'user-approval' }`, a per-tool function of the input, or one function for all calls | `needsApproval` on `tool()`: `true` or a function of the input returning a boolean |
| Outcomes | `'not-applicable'` (or `undefined`), `'approved'`, `'denied'`, `'user-approval'`; the object form adds a `reason` | approval required or not |
| Note | `needsApproval` is a deprecated fallback, except in `WorkflowAgent`, which uses it | v6 has no `toolApproval`; v7-style config there gates nothing |

Local docs: v7 `node_modules/ai/docs/03-agents/06-tool-approvals.mdx`, v6
`03-ai-sdk-core/15-tools-and-tool-calling.mdx`; online:
[Tool Approvals](https://ai-sdk.dev/docs/agents/tool-approvals) and
[policy-based approvals](https://ai-sdk.dev/docs/agents/policy-tool-approvals).

Derive per-request policy from trusted server context. Make denials final for
that operation, and avoid repeating information already presented in a tool
card. On the client, answer with
`addToolApprovalResponse({ id: part.approval.id, approved, reason? })` and set
`useChat({ sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses })`
so the conversation continues once every approval has a response.

## Render transitions

Handle the installed typed tool-part union rather than casting it to a loose
object. The ordinary state set includes:

| State | UI responsibility |
| --- | --- |
| `input-streaming` | Partial input; no execution or approval controls yet |
| `input-available` | Input complete; operation may still be pending |
| `approval-requested` | Show the proposed action and manual decision when applicable |
| `approval-responded` | Decision recorded; continuation may be pending |
| `output-available` | Render validated result |
| `output-denied` | Show cancellation/denial |
| `output-error` | Safe error and supported recovery |

A part can reach `input-available` before the approval request, so the card
changes from a loading to a decision variant. V7 automatic decisions also pass
through `approval-requested`, with `approval.isAutomatic: true`: show decision
controls only when it is falsy (the generated AI Elements `Confirmation` does
not check it). The policy's reason is `approval.requestReason`; the decision's
is `approval.reason`.

Ensure an exiting loading animation cannot block the decision controls. For
example, `AnimatePresence mode="wait"` mounts the approval card only after the
loading variant's exit finishes. Verify transitions in the UI; agent-level evals
cannot see a stuck approval card.

## Replay security

A client can modify round-tripped history. Bind approval to the server-issued
operation, validated inputs, user and conversation. For sensitive tools set
`experimental_toolApprovalSecret` (v7, recent v6): the server HMAC-signs each
request over tool name, call ID and input, and rejects unsigned or altered
approvals. Every instance needs the same secret. `WorkflowAgent` takes an
environment-variable reference instead of the raw value. Preserve the
signature through history conversion.

Recheck authorization when execution resumes. Keep signing secrets on the
server, and make irreversible operations idempotent. Test denial, missing or
tampered approvals, changed inputs, reconnect and repeated submission.
