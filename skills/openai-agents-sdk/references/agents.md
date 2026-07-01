# Agents

## Basic Agent Creation

```python
from agents import Agent, Runner

agent = Agent(
    name="Assistant",
    instructions="You are a helpful assistant.",
    model="gpt-5.4",  # or "gpt-5.4-mini", "gpt-5.4-nano"
)

# Synchronous execution
result = Runner.run_sync(agent, "Tell me a joke")
print(result.final_output)

# Asynchronous execution
result = await Runner.run(agent, "Tell me a joke")
```

## Other Providers (LiteLLM)

`openai-agents` supports non-OpenAI models through [LiteLLM](https://docs.litellm.ai/), which normalizes 100+ providers (Azure, Anthropic, Bedrock, Vertex AI, Ollama, ...) behind one interface. Two integration approaches exist:

### Direct model instantiation

Pass a `litellm/<provider>/<model>` string, or instantiate `LitellmModel` directly (shown here with Azure — swap the prefix for other providers):

```python
import os
from typing import Union
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "azure")  # this project's own convention, not SDK-mandated
MODEL = os.getenv("MODEL", "gpt-5.4")

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
    model="gpt-5.4",
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
    model="gpt-5.4",
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
