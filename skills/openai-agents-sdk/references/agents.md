# Agents and provider wiring

Read [model docs](https://openai.github.io/openai-agents-python/models/) and the
installed package source. Omitting `model` uses SDK defaults, which can change;
`OPENAI_DEFAULT_MODEL` is an SDK setting, while a custom app variable needs
explicit wiring. Default ModelSettings are not universal across model families.

Configure only settings supported by the selected provider/model. Reasoning,
sampling and tool support differ by endpoint. Do not infer capabilities or a
model family from an Azure deployment's user-defined name.

Azure can use native OpenAI model classes with the configured async Azure
client. Choose Responses/Chat Completions from deployed capabilities and the
current Azure API contract. Read deployment configuration or documented Azure
management APIs to identify the deployment; do not rely on an old generic
listing endpoint.

LiteLLM/Any-LLM are beta adapters recommended when built-in integration points
are insufficient. They have independent model maps, imports and package extras.
A rejected parameter may be adapter capability metadata rather than the
provider; verify before enabling it. Silently dropping a requested reasoning
setting changes behavior.

Tracing is separate from model authentication. An Azure/LiteLLM key does not
authorize OpenAI trace uploads. Configure trace destination or disable uploads
according to the application's policy.

See [SDK models](https://openai.github.io/openai-agents-python/models/),
[LiteLLM integration](https://docs.litellm.ai/docs/tutorials/openai_agents_sdk)
and the configured provider's current docs.
