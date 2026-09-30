# Tool execution boundaries and approvals

Use typed function tools for application operations; keep tenant/role checks,
input validation and idempotency in the executor. Model input/context is not
authorization. Tool errors returned to the model or UI need the app's safe
formatting policy. By default, `@function_tool` catches exceptions and returns
their message to the model; supply `failure_error_function` to sanitize it, or
`None` to re-raise. `timeout=` bounds a call; it does not make side effects
transactional. `from agents.decorators import tool` is an alias in current
releases (verified in 0.22.3).

Hosted tools run under provider contracts; local tools execute in the app's
runtime or sandbox. Confirm installed tool types and endpoint support in
[tools docs](https://openai.github.io/openai-agents-python/tools/). Do not assume
function-tool guardrails cover hosted shell, computer, MCP or patch tools.

Use `agent.as_tool()` when the manager consumes a child result and retains
control. Use a handoff when the specialist should become the active agent.
Tool execution limits and cancellation apply to real side effects too.
Ordinary function-call dict/Pydantic results, including a structured
`as_tool()` final output, default to `str(value)` in 0.22.3. Declared output
schemas serialize JSON; recognized `ToolOutputText`/image/file content retains
its structured format. Programmatic calls have separate JSON serialization.
Return JSON text or use `custom_output_extractor` when JSON formatting matters.
`tool_use_behavior="stop_on_first_tool"` or
`StopAtTools(stop_at_tool_names=[...])` returns a selected tool output as the
final result; `Agent.reset_tool_choice` defaults to `True` so a forced tool
choice does not force calls forever.

For model-written programmatic tool calling (`ProgrammaticToolCallingTool`, a
hosted Responses tool), verify the selected model and installed SDK
constraints, allowed callers and tool exposure before enabling it. A general
function-tool list is not automatically callable from model-generated code.

Use SDK human-in-the-loop interruption/resume state when the task needs approval.
Tie the decision to an authorized server-issued run/tool call and recheck
policy before executing it; do not trust client-edited run state.
`result.interruptions` contains approval items; use `state = result.to_state()`,
`state.approve(item)` / `state.reject(item)`, then resume with
`await Runner.run(original_agent, state)`. Restore serialized state with
`await RunState.from_string(original_agent, text)`; that method is async and
the serialized state includes run context. Pass `context_override=` to replace
that saved context with trusted server context; approval decisions and usage
still come from the string (verified in 0.22.3).
