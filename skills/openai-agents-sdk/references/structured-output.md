# Structured Output

## AgentOutputSchema with Pydantic

```python
from pydantic import BaseModel, Field
from agents import Agent, Runner, AgentOutputSchema, ModelSettings
from openai.types.shared.reasoning import Reasoning

# Pydantic model for response structure
class ProductRecommendationLite(BaseModel):
    product_id: str = Field(description="Unique product ID")
    name: str = Field(description="Product name")
    relevance_reason: str = Field(description="Why this product matches")
    match_score: float = Field(ge=0, le=1, description="Match score 0-1")

class ProductSelectionOutput(BaseModel):
    products: list[ProductRecommendationLite] = Field(description="Selected products")

# Agent with strict JSON schema output
agent = Agent(
    name="ProductSelector",
    instructions="Select the 10 best products matching user request...",
    model=get_model(),
    model_settings=ModelSettings(
        max_tokens=64000,
        # Reasoning effort: "none", "low", "medium", "high"
        reasoning=Reasoning(effort="low"),
    ),
    # strict_json_schema=True forces LLM to return valid JSON
    output_type=AgentOutputSchema(ProductSelectionOutput, strict_json_schema=True),
)

result = await Runner.run(agent, "Find products for family hiking trip")
output: ProductSelectionOutput = result.final_output

# Use the result
for product in output.products:
    print(f"{product.name}: {product.score} - {product.relevance_reason}")
```

## Simple Output Type

```python
from dataclasses import dataclass
from typing import Literal

@dataclass
class EvaluationFeedback:
    feedback: str
    score: Literal["pass", "needs_improvement", "fail"]

evaluator = Agent[None](
    name="Evaluator",
    instructions="Evaluate content and provide feedback.",
    output_type=EvaluationFeedback,
)

result = await Runner.run(evaluator, "Review this story outline...")
evaluation: EvaluationFeedback = result.final_output
print(f"Score: {evaluation.score}, Feedback: {evaluation.feedback}")
```

## ModelSettings

```python
from agents import Agent, ModelSettings
from openai.types.shared.reasoning import Reasoning

agent = Agent(
    name="Assistant",
    instructions="Be helpful.",
    model="gpt-5.2",
    model_settings=ModelSettings(
        max_tokens=32000,
        temperature=0.7,
        tool_choice="required",  # Force tool usage
        reasoning=Reasoning(effort="medium"),  # GPT-5 reasoning
    ),
)
```

## ModelSettings Options

| Option | Description |
|--------|-------------|
| `max_tokens` | Maximum tokens in response |
| `temperature` | Randomness (0.0-2.0) |
| `top_p` | Nucleus sampling |
| `tool_choice` | "auto", "required", "none" |
| `reasoning` | Reasoning effort for GPT-5 models |
| `presence_penalty` | Penalize repeated topics |
| `frequency_penalty` | Penalize repeated tokens |

## Non-Strict Output

For schemas that don't support strict mode:

```python
from agents import Agent, AgentOutputSchema

class FlexibleOutput(BaseModel):
    data: dict  # dict type not supported in strict mode
    notes: str

agent = Agent(
    name="Flexible",
    instructions="Return flexible data.",
    output_type=AgentOutputSchema(FlexibleOutput, strict_json_schema=False),
)
```
