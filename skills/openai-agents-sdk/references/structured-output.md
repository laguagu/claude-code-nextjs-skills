# Structured output

Use `output_type` with a supported Pydantic/dataclass shape or
`AgentOutputSchema` when the task needs a schema. Confirm strict-schema
compatibility in the installed SDK and provider.
`AgentOutputSchema(T, strict_json_schema=False)` disables strict schema mode;
the SDK still validates returned JSON with its Pydantic TypeAdapter. A schema
with unsupported `additionalProperties` (for example a bare `dict` field) can
raise `UserError` in strict mode; prefer an explicit compatible type.

A structurally valid object can still contain incorrect claims or unauthorized
IDs. Validate those against the app's data and policy.

Configure ModelSettings from the actual model/endpoint capabilities. A supported
field in the SDK does not mean every provider accepts it; avoid universal
temperature/reasoning assertions and copied settings tables.

Read [agents](https://openai.github.io/openai-agents-python/agents/),
[model settings](https://openai.github.io/openai-agents-python/ref/model_settings/)
and the installed output-schema types.
