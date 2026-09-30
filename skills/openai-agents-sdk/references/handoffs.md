# Handoffs and delegation

A handoff makes the specialist the active agent; it continues the conversation
and produces the final output (`result.last_agent`). `agent.as_tool()` returns
the child's output to the manager. Both are model-selected; use ordinary code
for deterministic routing.

- `Agent(handoffs=[billing])` or `handoff(billing, input_filter=..., on_handoff=...,
  input_type=...)`. The model sees a tool named `transfer_to_<agent_name>`
  (`transfer_to_billing_agent`).
- The receiving agent sees the full conversation by default. Narrow it with
  `input_filter` per handoff or `RunConfig.handoff_input_filter`.
  `agents.extensions.handoff_filters.remove_all_tools` drops tool items, not tool
  content already copied into messages. `RunConfig.nest_handoff_history` is an
  opt-in beta and does not redact.
- A filter takes and returns `HandoffInputData`. Return
  `dataclasses.replace(data, input_history=...)` so fields added by newer SDKs
  survive; keep tool call/result pairs intact.
- `input_type` is model-written metadata (reason, priority) passed to
  `on_handoff`; it does not replace the conversation the specialist receives.
  Authorize parsed values in `on_handoff` and raise to stop: the transfer
  proceeds once it returns.
- The specialist's input guardrails do not run; tool guardrails and approvals on
  its tools do.
- Streaming emits `handoff_requested`, then `handoff_occured` (sic) and an
  `agent_updated_stream_event`, not `tool_called`.

Official docs: [handoffs](https://openai.github.io/openai-agents-python/handoffs/),
[orchestration](https://openai.github.io/openai-agents-python/multi_agent/).
