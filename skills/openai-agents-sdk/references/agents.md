# Agents

## Contents

- [Basic Agent Creation](#basic-agent-creation)
- [Other Providers (LiteLLM)](#other-providers-litellm)
- [Azure OpenAI without LiteLLM](#azure-openai-without-litellm-native-client)
- [Dynamic System Prompt](#dynamic-system-prompt)
- [Loading Prompts from Files](#loading-prompts-from-files)
- [Agent Configuration Options](#agent-configuration-options)

## Basic Agent Creation

The minimal `Agent` + `Runner` example lives in SKILL.md (Quick Reference → Basic
Agent) and is not repeated here. Two things that example does not show:

- **Omitting `model=` is a choice, not a safe default.** The SDK ships its own
  default model (currently `gpt-5.6-luna` with `reasoning.effort="none"` and
  `verbosity="low"`), and that default changes between releases. Set the model
  explicitly in production code so an upstream change cannot swap tiers silently.
- **Use explicit model IDs when tier choice matters.** `gpt-5.6` is an alias for
  `gpt-5.6-sol`; the explicit `gpt-5.6-sol`, `gpt-5.6-terra` and
  `gpt-5.6-luna` IDs make the intended tier clear. Verify current IDs from the
  model catalog (`https://developers.openai.com/api/docs/models.md`).

## Other Providers (LiteLLM)

`openai-agents` supports non-OpenAI models through [LiteLLM](https://docs.litellm.ai/), which normalizes 100+ providers (Azure, Anthropic, Bedrock, Vertex AI, Ollama, ...) behind one interface. Install the extra first: `pip install "openai-agents[litellm]"` (or `uv add "openai-agents[litellm]"`). The SDK docs classify LiteLLM (and Any-LLM) as **beta** integrations, recommended only when the built-in integration points are insufficient — for Azure OpenAI specifically, the native path further below needs no extra dependency. Two LiteLLM integration approaches exist:

### Direct model instantiation

Pass a `litellm/<provider>/<model>` string, or instantiate `LitellmModel` directly (shown here with Azure — swap the prefix for other providers):

```python
import os
from typing import Union
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "azure")  # this project's own convention, not SDK-mandated
MODEL = os.getenv("MODEL", "gpt-5.6-sol")  # Azure: the deployment name, not the catalog ID

def get_model() -> Union[str, LitellmModel]:
    """Get model based on provider."""
    if LLM_PROVIDER == "azure":
        # azure/ prefix tells LiteLLM to use Azure endpoint
        # requires AZURE_API_KEY, AZURE_API_BASE, AZURE_API_VERSION —
        # see LiteLLM's provider docs below for current names/values, they change over time
        return LitellmModel(model=f"azure/{MODEL}")
    # Direct OpenAI
    return MODEL

agent = Agent(
    name="Assistant",
    instructions="You are helpful.",
    model=get_model(),  # Works with both Azure and OpenAI
)
```

### LiteLLM proxy

Run a LiteLLM proxy server and point the SDK at it through a custom `ModelProvider`, authenticating with `LITELLM_API_KEY` (LiteLLM's own key, not the underlying provider's) against `LITELLM_BASE_URL`. Useful for centralized key management/routing across many providers. See LiteLLM's [OpenAI Agents SDK tutorial](https://docs.litellm.ai/docs/tutorials/openai_agents_sdk) for the full setup — it's a different wiring than direct instantiation above, not an alternative env var naming for the same thing.

### References

- **Provider list & model string prefixes:** https://openai.github.io/openai-agents-python/models/
- **Per-provider env vars (Azure, Anthropic, Bedrock, ...):** https://docs.litellm.ai/docs/providers

## Azure OpenAI without LiteLLM (native client)

Azure OpenAI speaks the OpenAI API, so the SDK's own model classes work with an
`AsyncAzureOpenAI` client — no extra dependency:

```python
import os
from openai import AsyncAzureOpenAI
from agents import (
    Agent, OpenAIChatCompletionsModel,
    set_default_openai_client, set_default_openai_api, set_tracing_disabled,
)

# AsyncAzureOpenAI also auto-reads AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT
# and OPENAI_API_VERSION if you prefer env vars over explicit arguments.
client = AsyncAzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_API_KEY"],
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version=os.environ["OPENAI_API_VERSION"],
)

# Option A — one agent, Chat Completions against a named deployment
agent = Agent(
    name="Assistant",
    instructions="You are helpful.",
    model=OpenAIChatCompletionsModel(model="my-gpt-deployment", openai_client=client),
)

# Option B — process-wide default for every agent
set_default_openai_client(client, use_for_tracing=False)
set_default_openai_api("chat_completions")  # only if the deployment lacks the Responses API
set_tracing_disabled(True)                  # or keep OPENAI_API_KEY set for the trace uploader
```

`use_for_tracing=False` matters: trace uploads go to OpenAI's platform and need a
real `OPENAI_API_KEY`; with an Azure-only setup either disable tracing or route
spans elsewhere (see patterns.md → Tracing).

## Dynamic System Prompt

```python
from agents import Agent, Runner, RunContextWrapper

def dynamic_instructions(
    ctx: RunContextWrapper[dict], agent: Agent[dict]
) -> str:
    user_name = ctx.context.get("user_name", "User")
    return f"You are helping {user_name}. Be friendly and helpful."

agent = Agent(
    name="DynamicBot",
    instructions=dynamic_instructions,  # Function instead of string
    model="gpt-5.6-sol",
)

result = await Runner.run(
    agent,
    "Hello!",
    context={"user_name": "Alice"},
)
```

## Loading Prompts from Files

```python
from pathlib import Path

PROMPTS_DIR = Path(__file__).parent / "prompts"

def load_prompt(filename: str) -> str:
    return (PROMPTS_DIR / filename).read_text(encoding="utf-8")

agent = Agent(
    name="Planner",
    instructions=load_prompt("planner.md"),
    model="gpt-5.6-sol",
)
```

## Agent Configuration Options

| Option | Description |
|--------|-------------|
| `name` | Agent identifier |
| `instructions` | System prompt (string or function) |
| `model` | Model name or LitellmModel instance |
| `tools` | List of tools the agent can use |
| `handoffs` | List of agents to delegate to |
| `output_type` | Pydantic model for structured output |
| `model_settings` | ModelSettings for fine-tuning |
| `input_guardrails` | Input validation functions |
| `output_guardrails` | Output validation functions |
