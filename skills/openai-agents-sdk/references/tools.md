# Tool execution boundaries

Use typed function tools for application operations; keep tenant/role checks,
input validation and idempotency in the executor. Model input/context is not
authorization. Tool errors returned to the model or UI need the app's safe
formatting policy.

Hosted tools run under provider contracts; local tools execute in the app's
runtime or sandbox. Confirm installed tool types and endpoint support in
[tools docs](https://openai.github.io/openai-agents-python/tools/). Do not assume
function-tool guardrails cover hosted shell, computer, MCP or patch tools.

Use `agent.as_tool()` when the manager consumes a child result and retains
control. Use a handoff when the specialist should become the active agent.
Tool execution limits and cancellation apply to real side effects too.

For model-written programmatic tool calling, verify the selected Responses
model and installed SDK constraints, allowed callers and tool exposure before
enabling it. A general function-tool list is not automatically callable from
model-generated code.

Use SDK human-in-the-loop interruption/resume state when the task needs approval.
Tie the decision to an authorized server-issued run/tool call and recheck
policy before executing it; do not trust client-edited run state.
