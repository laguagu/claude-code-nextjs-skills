# Orchestration, run limits and tracing

Use ordinary code for fixed steps: run one agent, pass `result.final_output` or
`result.to_input_list()` to the next, `asyncio.gather` independent runs. Add a
manager (`as_tool`) or triage (handoffs) when the model should choose the
route. A judge loop needs a retry bound and criteria checkable from the evidence
it receives.

- `max_turns` defaults to 10 per run (`None` disables) and raises
  `MaxTurnsExceeded`; `error_handlers={"max_turns": fn}` returning
  `RunErrorHandlerResult(final_output=...)` ends it gracefully instead.
- A turn limit is not a wall-clock timeout: use `ModelSettings(timeout=...)` per
  model call and `@function_tool(timeout=...)` per tool. Neither makes side
  effects transactional; durable execution needs its runtime's recovery contract.
- Since 0.22, non-streaming Responses calls ending `failed` or `incomplete` raise
  `ModelBehaviorError`.

## Tracing

On by default. Traces go to OpenAI and include model and tool inputs/outputs;
`RunConfig(trace_include_sensitive_data=False)` or
`OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA=0` omits them.

- Group runs with `with trace("Workflow"):`, wrap app work in
  `custom_span("name")`, label with `RunConfig(workflow_name=..., group_id=...,
  trace_metadata=...)`.
- Without an OpenAI platform key (Azure, LiteLLM) uploads fail with 401:
  `set_tracing_disabled(True)` / `OPENAI_AGENTS_DISABLE_TRACING=1`,
  `set_tracing_export_api_key(key)`, or another processor.
- `add_trace_processor(p)` adds a destination and keeps the OpenAI exporter;
  `set_trace_processors([p])` replaces it.
- Tests: `RunConfig(tracing_disabled=True)`.

Official docs: [orchestration](https://openai.github.io/openai-agents-python/multi_agent/),
[running agents](https://openai.github.io/openai-agents-python/running_agents/),
[tracing](https://openai.github.io/openai-agents-python/tracing/).
