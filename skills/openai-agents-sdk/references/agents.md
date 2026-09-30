# Agents and provider wiring

Read [model docs](https://openai.github.io/openai-agents-python/models/) and the
installed package source. Omitting `model` uses SDK defaults, which can change
(0.22.3 fallback: `gpt-5.6-luna`, not a model recommendation);
`OPENAI_DEFAULT_MODEL` is an SDK setting, while a
custom app variable needs explicit wiring. Tuned default ModelSettings apply
in 0.22.3 only to supported `gpt-5` names; other IDs, including `gpt-6.1-sol`, get a
plain `ModelSettings()` and the API's default reasoning effort, so set
`reasoning` explicitly. The installed `agents/models/default_models.py` shows
the current rules.

Use the [current API model catalog](https://developers.openai.com/api/docs/models)
and [model-selection guidance](https://developers.openai.com/api/docs/guides/model-selection)
for a new choice; check account/provider access and the chosen model's API page.

Configure only settings supported by the selected provider/model. Reasoning,
sampling and tool support differ by endpoint. Do not infer capabilities or a
model family from an Azure deployment's user-defined name.

Azure can use native OpenAI model classes with an `AsyncAzureOpenAI` client:
per agent via `OpenAIResponsesModel` or
`OpenAIChatCompletionsModel(model=<deployment>, openai_client=client)`, or
process-wide via `set_default_openai_client(client, use_for_tracing=False)`
plus `set_default_openai_api("chat_completions")` when the deployment lacks
Responses. Choose Responses/Chat Completions from deployed capabilities and the
current Azure API contract. GPT-6 Astra and GPT-6.1 Sol require Responses for
tool calling; GPT-6 Sol and Luna allow function calling on Chat
Completions only with reasoning effort `none`; an agent needing tools and
reasoning must use Responses (`LitellmModel` always uses Chat Completions).
See the [GPT-6 API guide](https://developers.openai.com/api/docs/guides/latest-model)
and the Azure deployment's capabilities before choosing an adapter.
Read deployment configuration or documented Azure management APIs to identify
the deployment; do not rely on an old generic listing endpoint.

LiteLLM/Any-LLM are beta adapters recommended when built-in integration points
are insufficient. They have independent model maps, imports and package extras.
A rejected parameter may be adapter capability metadata rather than the
provider: LiteLLM raises `UnsupportedParamsError ... ['reasoning_effort']` for
an Azure deployment name its model map does not recognize. After confirming the
deployment supports it, pass
`ModelSettings(reasoning=..., extra_args={"allowed_openai_params": ["reasoning_effort"]})`;
`litellm.drop_params=True` silently discards the setting.

Tracing is separate from model authentication. An Azure/LiteLLM key does not
authorize OpenAI trace uploads. Configure trace destination or disable uploads
according to the application's policy.

See [SDK models](https://openai.github.io/openai-agents-python/models/),
[LiteLLM integration](https://docs.litellm.ai/docs/tutorials/openai_agents_sdk)
and the configured provider's current docs.
