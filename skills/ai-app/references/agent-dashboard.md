# Agent dashboard contract

Use `ai-sdk` to select the installed-major agent API and `ai-elements` for
available execution UI. A dashboard should expose the run's purpose, current
state, useful results and actions the user can take.

Keep server execution state separate from transient display state. Stable run
and tool-call IDs connect streamed updates, stored results and approval decisions.
Handle cancellation, timeout, tool failure and process restart according to the
chosen runtime; an in-memory loop does not provide durable resumption.

Approvals must pause the operation before its side effect and bind the decision
to the actual server-issued request. Denial is a terminal tool outcome, not a
loading state. In AI SDK 6 use tool-level `needsApproval`; for SDK 7 follow the
selected agent's approval API, including WorkflowAgent's separate semantics.

Multiple agents, model selectors, timelines and metrics are optional. Add them
only when they help the user operate the app. Verify approval/denial and tool
transitions in the browser, not just successful model output.
