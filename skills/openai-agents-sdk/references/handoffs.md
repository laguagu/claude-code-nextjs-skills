# Delegation and history

A handoff changes the active agent, which continues the conversation. An
agent-as-tool returns a result to the manager. Either can be model-selected;
handoff versus tool is a control-flow decision, not a deterministic-routing
guarantee.

Use the installed handoff API for declared input, hooks and filtering. Preserve
the current `HandoffInputData` fields when changing history (for example with a
dataclass replacement) rather than reconstructing the structure field by field.

Filter only what the specialist should not receive. Keep tool-call/result and
provider protocol context valid. Use built-in filters when they meet the
contract and inspect their effect on the actual conversation. The recipient
gets full conversation history by default; handoff `input_type` supplies
model-written metadata to `on_handoff`, not replacement conversation input.
`remove_all_tools` removes tool items but not text already copied into messages;
`nest_handoff_history` summarizes history and is not a redaction boundary.

Local run context is separate from model-visible history. Authorization,
guardrail coverage and tool permissions need checking in the receiving path too.

Read [handoff docs](https://openai.github.io/openai-agents-python/handoffs/)
and [orchestration docs](https://openai.github.io/openai-agents-python/multi_agent/)
for compatible implementations.
