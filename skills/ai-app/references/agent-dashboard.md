# Agent dashboard contract

A dashboard should expose the run's purpose, current state, useful results and
the actions the user can take. Multiple agents, model selectors, timelines and
metrics are optional; add them only when they help the user operate the app.

Keep server execution state separate from transient display state. Stable run
and tool-call IDs connect streamed updates, stored results and approval
decisions. An in-memory `ToolLoopAgent` loop does not survive a restart;
durable runs need `WorkflowAgent` or another durable runtime (see `ai-sdk-7`).

AI Elements covers the usual pieces: `Tool` (`ToolHeader`, `ToolContent`,
`ToolInput`, `ToolOutput`) for tool parts, `Confirmation` for approvals, and
`Reasoning`, `Task`, `Plan` or `Queue` for progress. Check the generated source
for props.

Approvals pause the operation before its side effect and bind the decision to
the server-issued request. Denial is a terminal tool outcome, not a loading
state. v7 configures `toolApproval` on the agent or call; v6 uses `needsApproval`
on the tool. See [tool approval](../../nextjs-chatbot/hitl.md) for states,
automatic decisions and signing.

Verify approval, denial and tool-error transitions in the browser, not just
successful model output.
