# Guardrails

| Kind | Declare | Runs | Tripwire raises |
| --- | --- | --- | --- |
| Agent input | `@input_guardrail`, `Agent(input_guardrails=[...])` | First agent only; parallel with it by default | `InputGuardrailTripwireTriggered` |
| Agent output | `@output_guardrail`, `Agent(output_guardrails=[...])` | Agent producing the final output, after it finishes | `OutputGuardrailTripwireTriggered` |
| Tool | `@tool_input_guardrail` / `@tool_output_guardrail`, `@function_tool(tool_input_guardrails=[...])` | Every call of that `FunctionTool`; local MCP tools when the server sets them | `ToolInputGuardrailTripwireTriggered` / `ToolOutputGuardrailTripwireTriggered` |

Agent guardrails return `GuardrailFunctionOutput(output_info=..., tripwire_triggered=...)`;
the exception carries it as `exc.guardrail_result.output`. Tool guardrails return
`ToolGuardrailFunctionOutput.allow()`, `.reject_content(message)` (the model
sees the message, the run continues) or `.raise_exception()`.

- A parallel input guardrail can let the agent spend tokens and run tools before
  the tripwire cancels it. `@input_guardrail(run_in_parallel=False)` completes
  first.
- Output guardrails cannot undo tool side effects or text already streamed.
- In a tool guardrail, `data.context.tool_arguments` is the raw JSON string:
  `json.loads(data.context.tool_arguments or "{}")`.
- Tool guardrails skip hosted tools, `ComputerTool`/`ShellTool`/`LocalShellTool`/
  `ApplyPatchTool`, handoff calls and `Agent.as_tool()`. With approval, tool
  input guardrails run after approval unless
  `RunConfig(tool_execution=ToolExecutionConfig(pre_approval_tool_input_guardrails=True))`.
- A tripwire and an exception raised inside the guardrail persist session
  history differently. Catch the tripwire types explicitly, not a broad `except`.
- Output guardrails with `conversation_id`/`previous_response_id` on a Responses
  model raise `UserError`: rejected output cannot be removed from server history.

Keep access control in application and tool code. Test a rejected input, a tool
denial, an output tripwire and the streaming path. Details: the official
[guardrails docs](https://openai.github.io/openai-agents-python/guardrails/).
