# Agents

## Basic Agent Creation

```python
from agents import Agent, Runner

agent = Agent(
    name="Assistant",
    instructions="You are a helpful assistant.",
    model="gpt-5.2",  # or "gpt-5", "gpt-5.2-nano"
)

# Synchronous execution
result = Runner.run_sync(agent, "Tell me a joke")
print(result.final_output)

# Asynchronous execution
result = await Runner.run(agent, "Tell me a joke")
```

## Azure OpenAI (LiteLLM)

```python
import os
from typing import Union
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "azure")
MODEL = os.getenv("MODEL", "gpt-5.2")

def get_model() -> Union[str, LitellmModel]:
    """Get model based on provider."""
    if LLM_PROVIDER == "azure":
        # azure/ prefix tells LiteLLM to use Azure endpoint
        return LitellmModel(model=f"azure/{MODEL}")
    # Direct OpenAI
    return MODEL

agent = Agent(
    name="Assistant",
    instructions="You are helpful.",
    model=get_model(),  # Works with both Azure and OpenAI
)
```

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
    model="gpt-5.2",
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
    model="gpt-5.2",
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
