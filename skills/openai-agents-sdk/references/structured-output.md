# Structured output

`Agent(output_type=T)` accepts a Pydantic model, dataclass, TypedDict, list or
anything a Pydantic `TypeAdapter` wraps; `result.final_output` is then a `T`.
The schema is strict by default: a type that cannot be made strict, such as a
bare `dict` field, raises `UserError` on the first run. Fix the type, or use
`output_type=AgentOutputSchema(T, strict_json_schema=False)`; generation is then
unenforced, so validate in the application.

- Providers without JSON-schema output return a 400 on `response_format`
  (some accept only `json_object`). Check the actual endpoint.
- A structurally valid object can still contain wrong claims or unauthorized
  IDs. Validate against the app's data and policy.
- Set only the `ModelSettings` the model and endpoint accept. Supported
  reasoning efforts, and whether `temperature`/`top_p` are allowed alongside
  reasoning, differ per model; check its model page rather than copying a
  settings table. `Reasoning` comes from `openai.types.shared`.

Local: `help(agents.ModelSettings)` and `agents/agent_output.py`. Official docs:
[agents](https://openai.github.io/openai-agents-python/agents/),
[model settings](https://openai.github.io/openai-agents-python/ref/model_settings/).
