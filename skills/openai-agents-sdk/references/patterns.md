# Patterns

## Multi-Agent Workflow Pipeline

Example: 3-stage pipeline (ProductSelector -> SetOptimizer -> PlanGenerator)

```python
from pathlib import Path
from pydantic import BaseModel, Field
from agents import Agent, AgentOutputSchema, ModelSettings, RunConfig, Runner
from openai.types.responses import ResponseTextDeltaEvent
from openai.types.shared.reasoning import Reasoning
from collections.abc import AsyncIterator

# --- Pydantic Output Schemas ---

class ProductLite(BaseModel):
    product_id: str
    name: str
    score: float = Field(ge=0, le=1)

class ProductsOutput(BaseModel):
    products: list[ProductLite]

class TravelSet(BaseModel):
    set_id: str  # "compact", "balanced", "extended"
    name: str
    product_ids: list[str]

class SetsOutput(BaseModel):
    sets: list[TravelSet]
    recommended_set_id: str

# --- Prompt Loading ---

PROMPTS_DIR = Path(__file__).parent / "prompts"

def load_prompt(name: str) -> str:
    return (PROMPTS_DIR / name).read_text(encoding="utf-8")

# --- Agents ---

# Step 1: Select products (structured output)
product_selector = Agent(
    name="ProductSelector",
    instructions=load_prompt("product_selector.md"),
    model=get_model(),
    model_settings=ModelSettings(max_tokens=64000),
    output_type=AgentOutputSchema(ProductsOutput, strict_json_schema=True),
)

# Step 2: Optimize sets (structured output)
set_optimizer = Agent(
    name="SetOptimizer",
    instructions=load_prompt("set_optimizer.md"),
    model=get_model(),
    model_settings=ModelSettings(
        max_tokens=16000,
        reasoning=Reasoning(effort="low"),
    ),
    output_type=AgentOutputSchema(SetsOutput, strict_json_schema=True),
)

# Step 3: Generate plan (streaming, no schema)
plan_generator = Agent(
    name="PlanGenerator",
    instructions=load_prompt("plan_generator.md"),
    model=get_model(),
    model_settings=ModelSettings(
        max_tokens=32000,
        reasoning=Reasoning(effort="low"),
    ),
    # No output_type = free text for streaming
)

# --- Runner Functions ---

async def select_products(user_prompt: str, context: str) -> list[ProductLite]:
    """Step 1: Select products."""
    result = await Runner.run(
        product_selector,
        input=f"User: {user_prompt}\n\nProducts:\n{context}",
        run_config=RunConfig(
            workflow_name="ProductSelector",
            trace_metadata={"step": "select"},
        ),
    )
    output: ProductsOutput = result.final_output
    return output.products

async def optimize_sets(products: list[dict]) -> tuple[list[TravelSet], str]:
    """Step 2: Create optimized sets."""
    result = await Runner.run(
        set_optimizer,
        input=f"Products:\n{products}",
        run_config=RunConfig(workflow_name="SetOptimizer"),
    )
    output: SetsOutput = result.final_output
    return output.sets, output.recommended_set_id

async def generate_plan_stream(products: list[dict]) -> AsyncIterator[str]:
    """Step 3: Generate plan with streaming."""
    result = Runner.run_streamed(
        plan_generator,
        input=f"Create travel plan for:\n{products}",
        run_config=RunConfig(workflow_name="PlanGenerator"),
    )
    async for event in result.stream_events():
        if event.type == "raw_response_event":
            if isinstance(event.data, ResponseTextDeltaEvent):
                yield event.data.delta

# --- Full Workflow ---

async def travel_workflow(user_prompt: str, products_context: str):
    # Step 1
    products = await select_products(user_prompt, products_context)
    print(f"Selected {len(products)} products")

    # Step 2
    sets, recommended = await optimize_sets([p.model_dump() for p in products])
    print(f"Created {len(sets)} sets, recommended: {recommended}")

    # Step 3 - stream
    async for chunk in generate_plan_stream([p.model_dump() for p in products]):
        print(chunk, end="", flush=True)
```

## LLM as a Judge

Iterative improvement with evaluator agent:

```python
from dataclasses import dataclass
from typing import Literal
from agents import Agent, Runner, TResponseInputItem, trace

@dataclass
class Evaluation:
    score: Literal["pass", "needs_improvement", "fail"]
    feedback: str

generator = Agent(
    name="Generator",
    instructions="Generate content based on feedback.",
)

evaluator = Agent(
    name="Evaluator",
    instructions="Evaluate and provide feedback.",
    output_type=Evaluation,
)

async def generate_with_feedback(prompt: str) -> str:
    inputs: list[TResponseInputItem] = [{"role": "user", "content": prompt}]

    with trace("LLM as a judge"):
        while True:
            gen_result = await Runner.run(generator, inputs)
            inputs = gen_result.to_input_list()

            eval_result = await Runner.run(evaluator, inputs)
            evaluation: Evaluation = eval_result.final_output

            if evaluation.score == "pass":
                return gen_result.final_output

            inputs.append({"role": "user", "content": f"Feedback: {evaluation.feedback}"})
```

## Tracing

Group related agent runs together:

```python
from agents import Agent, Runner, trace, RunConfig

async def workflow(user_input: str):
    with trace("MyWorkflow"):
        # All Runner.run() calls inside this block
        # appear in the same trace
        result1 = await Runner.run(agent1, user_input)
        result2 = await Runner.run(agent2, result1.to_input_list())

    return result2.final_output

# RunConfig for metadata
result = await Runner.run(
    agent,
    input=message,
    run_config=RunConfig(
        workflow_name="ProductSelector",
        trace_metadata={"agent": "selector", "locale": "fi"},
    ),
)
```

## Parallelization

Run multiple agents concurrently:

```python
import asyncio
from agents import Agent, Runner

agent1 = Agent(name="Researcher", instructions="Research topics.")
agent2 = Agent(name="Analyzer", instructions="Analyze data.")
agent3 = Agent(name="Writer", instructions="Write content.")

async def parallel_workflow(topic: str):
    # Run research and analysis in parallel
    research_task = Runner.run(agent1, f"Research: {topic}")
    analysis_task = Runner.run(agent2, f"Analyze: {topic}")

    research_result, analysis_result = await asyncio.gather(
        research_task, analysis_task
    )

    # Combine results for writer
    combined_input = f"""
    Research: {research_result.final_output}
    Analysis: {analysis_result.final_output}
    """

    writer_result = await Runner.run(agent3, combined_input)
    return writer_result.final_output
```

## Routing

Route to specialized agents based on input:

```python
from agents import Agent, Runner, function_tool
from typing import Literal

@function_tool
def classify_intent(query: str) -> Literal["billing", "technical", "sales"]:
    """Classify user intent."""
    # In real app, could use another LLM or classifier
    if "invoice" in query or "payment" in query:
        return "billing"
    elif "error" in query or "bug" in query:
        return "technical"
    return "sales"

router = Agent(
    name="Router",
    instructions="Classify user intent using the classify tool.",
    tools=[classify_intent],
)

agents = {
    "billing": Agent(name="Billing", instructions="Handle billing."),
    "technical": Agent(name="Technical", instructions="Handle tech support."),
    "sales": Agent(name="Sales", instructions="Handle sales."),
}

async def route_and_handle(query: str):
    # First, classify
    router_result = await Runner.run(router, query)
    intent = router_result.final_output  # "billing", "technical", or "sales"

    # Route to specialist
    specialist = agents[intent]
    result = await Runner.run(specialist, query)
    return result.final_output
```

## Deterministic Workflows

Force specific tool execution order:

```python
from agents import Agent, ModelSettings

# Phase 1: Must search
search_agent = Agent(
    name="Searcher",
    instructions="Search for information.",
    tools=[search_tool],
    model_settings=ModelSettings(tool_choice="required"),
)

# Phase 2: Must analyze
analyzer = Agent(
    name="Analyzer",
    instructions="Analyze the search results.",
    tools=[analyze_tool],
    model_settings=ModelSettings(tool_choice="required"),
)

# Phase 3: Free response
writer = Agent(
    name="Writer",
    instructions="Write based on analysis.",
    # No tool_choice = free text response
)

async def deterministic_workflow(query: str):
    # Guaranteed order: search -> analyze -> write
    search_result = await Runner.run(search_agent, query)
    analysis_result = await Runner.run(analyzer, search_result.to_input_list())
    final_result = await Runner.run(writer, analysis_result.to_input_list())
    return final_result.final_output
```
