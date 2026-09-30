# Tool approval

Approval suspends a proposed tool operation until an explicit decision. It
complements server authorization; it does not establish a client's identity or
permission to act.

## Version and policy

Read [Tool Approvals](https://ai-sdk.dev/docs/agents/tool-approvals) and
[policy-based approvals](https://ai-sdk.dev/docs/agents/policy-tool-approvals)
for the installed version. Core v7 uses `toolApproval`; v6 uses tool-level
`needsApproval`. V7 retains the latter as a deprecated fallback, while the
separate WorkflowAgent contract still uses it.

Derive per-request policy from trusted server context. Make denials final for
that operation, and avoid repeating information already presented in a tool
card. Use `addToolApprovalResponse` and the compatible automatic-send helper
when a manual decision should continue a `useChat` conversation.

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
and manual ones must not produce duplicate approval controls. Ensure an exiting
loading animation cannot block the decision controls; verify transitions in the
UI instead of banning an animation library based on one integration failure.

## Replay security

A client can modify round-tripped history. Bind approval to the server-issued
operation, validated inputs, user and conversation. Where the installed SDK
supports signed approvals, use its signing/verification contract and preserve
the signature through history conversion. Core agents and WorkflowAgent have
different secret configuration; verify the actual API and pending-key behavior
in [current approval docs](https://ai-sdk.dev/docs/agents/tool-approvals).

Recheck authorization when execution resumes. Keep signing secrets on the
server, and make irreversible operations idempotent. Test denial, missing or
tampered approvals, changed inputs, reconnect and repeated submission.
