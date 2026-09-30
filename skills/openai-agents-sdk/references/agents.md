# Agents and provider wiring

The installed default and its settings:
`python -c "from agents.models import get_default_model as m, get_default_model_settings as s; print(m(), s())"`.

- Omitting `model` uses the SDK default (0.22.x: `gpt-5.6-luna`, reasoning
  effort `none`, verbosity `low`). `OPENAI_DEFAULT_MODEL` or
  `RunConfig(model=...)` override it; a custom app variable needs explicit wiring.
- Only names starting `gpt-5` get tuned defaults. Every other name gets bare
  `ModelSettings()`, i.e. the provider's default reasoning effort. Do not infer
  capabilities or a model family from an Azure deployment's user-defined name.
- `reasoning.mode` and `reasoning.context` are Responses-only; Chat Completions
  sends only `reasoning.effort`.

## Azure OpenAI with the native client

```python
from openai import AsyncAzureOpenAI  # reads AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, OPENAI_API_VERSION
from agents import Agent, OpenAIChatCompletionsModel

client = AsyncAzureOpenAI()
agent = Agent(name="Assistant",
              model=OpenAIChatCompletionsModel(model="<deployment name>", openai_client=client))
```

Use `OpenAIResponsesModel` when the deployment serves the Responses API.
Process-wide alternative: `set_default_openai_client(client, use_for_tracing=False)`,
plus `set_default_openai_api("chat_completions")` without Responses.

The Chat Completions path silently drops Responses-only fields
(`previous_response_id`, `conversation_id`, `prompt`);
`OpenAIProvider(use_responses=False, strict_feature_validation=True)` makes that
an error. `ToolSearchTool`, `ProgrammaticToolCallingTool`, `tool_namespace()` and
deferred tool loading are rejected there.

## LiteLLM and Any-LLM (beta adapters)

Use them when the built-in paths (`set_default_openai_client`, a `ModelProvider`
or a model object on `Agent.model`) do not cover the provider. LiteLLM:
`openai-agents[litellm]`, then `model="litellm/<provider>/<model>"` or
`LitellmModel(model="azure/<deployment>")` from
`agents.extensions.models.litellm_model`.

- Since 0.21 the SDK requires `openai>=3`, while LiteLLM 1.84+ pins `openai<3`:
  the resolver lands on LiteLLM 1.83.x, and requiring a newer LiteLLM is
  unsatisfiable.
- LiteLLM checks parameters against its own model map. For a deployment name it
  does not recognize (`azure/my-deploy`), `ModelSettings(reasoning=...)` raises
  `UnsupportedParamsError: azure does not support parameters: ['reasoning_effort']`.
  Allow it explicitly; `litellm.drop_params=True` silently discards the effort:

  ```python
  from openai.types.shared import Reasoning
  ModelSettings(reasoning=Reasoning(effort="low"),
                extra_args={"allowed_openai_params": ["reasoning_effort"]})
  ```
- Some backends report no usage unless `ModelSettings(include_usage=True)`.

An Azure or LiteLLM key does not authorize OpenAI trace uploads; see
[patterns.md](patterns.md#tracing).

Official docs: [models](https://openai.github.io/openai-agents-python/models/),
LiteLLM [providers](https://docs.litellm.ai/docs/providers).
