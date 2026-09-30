# Tool approval

Approval suspends a proposed tool operation until an explicit decision. It
complements server authorization; it does not establish a client's identity or
permission to act.

## Version and policy

| Contract | v7 core | v6 core |
| --- | --- | --- |
| Configure | `toolApproval` on `ToolLoopAgent`, `generateText` or `streamText`: per-tool map (for example `{ deleteFile: 'user-approval' }`), per-tool input function or a function for all calls | `needsApproval` on `tool()`: boolean or an input function returning a boolean |
| Outcomes | `'not-applicable'` (or `undefined`), `'approved'`, `'denied'`, `'user-approval'`; object form allows a `reason` on the last three statuses | Approval required or not |
| Boundary | `needsApproval` is a deprecated core fallback; `WorkflowAgent` still uses it | `toolApproval` gates nothing; without a type error v7-style config can execute the tool without asking |

Local docs: v7 `node_modules/ai/docs/03-agents/06-tool-approvals.mdx`, v6
`node_modules/ai/docs/03-ai-sdk-core/15-tools-and-tool-calling.mdx`. Online:
[Tool Approvals](https://ai-sdk.dev/docs/agents/tool-approvals) and
[policy-based approvals](https://ai-sdk.dev/docs/agents/policy-tool-approvals).

Derive per-request policy from trusted server context. Make denials final for
that operation, and avoid repeating information already presented in a tool
card. Reply with
`addToolApprovalResponse({ id: part.approval.id, approved })` (optional `reason`)
and use
`sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses`
when the conversation should continue after all manual decisions are recorded.

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

V7 can emit completed input before the approval request. Automatic decisions
also pass through `approval-requested`, with `approval.isAutomatic: true`;
show decision controls only for manual requests. A manual request's policy
reason is `approval.requestReason`; the decision reason (automatic or supplied
by the user) is `approval.reason`.
Check the generated component's behavior rather than assuming it distinguishes
these states. Ensure an exiting loading animation cannot block the decision
controls; verify transitions in the UI.

## Replay security

A client can modify round-tripped history. Bind approval to the server-issued
operation, validated inputs, user and conversation. For sensitive tools set
`experimental_toolApprovalSecret` on core agents/`generateText`/`streamText`
(verified in `ai@6.0.298` and `ai@7.0.124`; check earlier installed versions).
The server HMAC-signs the tool name, call ID and input; unsigned or altered
approvals are rejected. All instances need the same secret; reject missing
configuration when signing is required, since `undefined` disables it.
`WorkflowAgent` takes `{ environmentVariable: 'TOOL_APPROVAL_SECRET' }` instead
of a raw secret.
Preserve the signature and `inputSchemaInput` through persistence/conversion:
transformed schemas need the original input to reconstruct the approved value,
and fields removed by a transform can still be present in approval metadata.

Recheck authorization when execution resumes. Keep signing secrets on the
server, and make irreversible operations idempotent. Test denial, missing or
tampered approvals, changed inputs, reconnect and repeated submission.
