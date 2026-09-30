# Guardrail coverage

Agent input guardrails run for the first agent; output guardrails check the
final-output agent. They do not surround every intermediate handoff or tool.

Input guardrails default to parallel execution. The agent can already consume
tokens or execute tools before a tripwire cancels it. Use
`run_in_parallel=False` when the check must complete before the run starts.
Output guardrails happen after execution and cannot undo side effects or
already-streamed output.

Tool input/output guardrails use the FunctionTool pipeline. Hosted/built-in
execution tools and handoff calls have different coverage; local MCP tools can
use server-configured guardrails in supported releases. Verify the installed
coverage before assuming a generic policy applies. With approval, input tool
guardrails normally run after approval;
`RunConfig(tool_execution=ToolExecutionConfig(pre_approval_tool_input_guardrails=True))`
changes that order in 0.22.3.

Output guardrails combined with Responses server-managed history
(`conversation_id`, `previous_response_id` or `auto_previous_response_id`)
raise `UserError`: rejected output cannot be removed from that history.

A returned tripwire and a guardrail exception have different failure and
session-persistence semantics. Read the current
[guardrail documentation](https://openai.github.io/openai-agents-python/guardrails/)
for those details rather than writing a broad catch that hides the distinction.

Keep actual access control in application/tool code. Test a rejected input,
tool denial, output tripwire and relevant streaming behavior.
