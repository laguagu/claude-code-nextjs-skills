# Orchestration, run limits and tracing

Use ordinary application control flow for fixed steps and independent work.
Add managers, workers or judge loops when the task benefits from model-selected
routing or measured quality improvement. A judge needs bounded retries and
criteria grounded in the evidence it receives.

Set the run's `max_turns` for the product budget and handle
`MaxTurnsExceeded`. A turn limit does not impose a wall-clock timeout or make
tool side effects transactional. Durable execution needs the chosen runtime's
recovery contract.

Tracing is enabled by default and can include sensitive generation/tool data.
Configure the installed `trace_include_sensitive_data` / processor controls.
Group related work with a trace when useful; use custom spans for app work.

OpenAI uploads require suitable OpenAI credentials independently of the model
provider. Disable with `set_tracing_disabled` or the documented environment
setting, or configure a different processor. Replacing versus adding processors
changes destinations; verify the intended result.

Read [orchestration](https://openai.github.io/openai-agents-python/multi_agent/),
[running agents](https://openai.github.io/openai-agents-python/running_agents/)
and [tracing](https://openai.github.io/openai-agents-python/tracing/).
