# Tools

Keep tenant/role checks, input validation and idempotency in the tool executor.
Model input and run context are not authorization.

- `@function_tool` (alias `@tool` from `agents.decorators`) builds the schema from
  type hints and the docstring. `timeout=`, `needs_approval=`, guardrails and
  `failure_error_function=` are decorator arguments.
- A raising tool does not end the run: the default error function sends the
  exception message to the model. Pass a custom `failure_error_function` to keep
  internal details out, or `None` to re-raise.
- `ModelSettings(tool_choice="required")` forces a call; `Agent.reset_tool_choice`
  (default `True`) resets it after a tool call so the loop can finish.
  `tool_use_behavior="stop_on_first_tool"` or `StopAtTools([...])` makes a tool's
  result the final output.

Hosted tools run on OpenAI through the Responses API: `WebSearchTool`,
`FileSearchTool`, `CodeInterpreterTool`, `HostedMCPTool`, `ImageGenerationTool`,
`ToolSearchTool`. Local runtime tools execute in your process or sandbox:
`ComputerTool`, `ShellTool`, `LocalShellTool`, `ApplyPatchTool`; approval for
`ShellTool`/`ApplyPatchTool` is opt-in (`needs_approval` defaults to `False`).
Function-tool guardrails cover none of these. Confirm names in the installed
`agents/tool.py` or the official [tools docs](https://openai.github.io/openai-agents-python/tools/).

`ProgrammaticToolCallingTool` (0.19+) lets the model call tools from generated
JavaScript: Responses models only, at most one per agent, and a tool is callable
from the program only with `allowed_callers=["programmatic"]` (or
`["direct", "programmatic"]`). Keep approval-sensitive tools direct.

`agent.as_tool(tool_name=..., tool_description=...)` returns the child's output
to the manager, which keeps control; it accepts `parameters=`, `max_turns=` and
`needs_approval=`. A handoff makes the specialist active ([handoffs.md](handoffs.md)).

## Approval and resume

```python
result = await Runner.run(agent, message)
if result.interruptions:                  # ToolApprovalItem entries
    state = result.to_state()             # state.to_string() to persist
    for item in result.interruptions:
        state.approve(item)               # or state.reject(item, rejection_message=...)
    result = await Runner.run(agent, state)   # the original top-level agent
```

Restore a persisted state with `await RunState.from_string(agent, text)`; it is
async. The serialized state includes run context, so keep secrets out of it.
Tie decisions to an authorized server-side run and recheck policy before
resuming; do not trust client-edited state. Approvals raised inside handoffs or
nested `as_tool()` runs surface on the outer run. See the official
[human-in-the-loop docs](https://openai.github.io/openai-agents-python/human_in_the_loop/).
