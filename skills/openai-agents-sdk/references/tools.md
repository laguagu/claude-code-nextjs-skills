# Tools

## Function Tools (@function_tool)

```python
from typing import Annotated
from agents import Agent, Runner, function_tool

@function_tool
def get_weather(city: Annotated[str, "City name"]) -> str:
    """Get weather for a city."""
    return f"Weather in {city}: Sunny, 20C"

@function_tool
async def search_database(query: Annotated[str, "Search query"]) -> list[dict]:
    """Search products in database."""
    # Async function - can await database calls
    return [{"id": "1", "name": "Hiking boots"}]

agent = Agent(
    name="Assistant",
    instructions="Help users find information.",
    tools=[get_weather, search_database],
)
```

## Tool with Multiple Parameters

```python
@function_tool
def book_flight(
    origin: Annotated[str, "Departure city"],
    destination: Annotated[str, "Arrival city"],
    date: Annotated[str, "Travel date (YYYY-MM-DD)"],
    passengers: Annotated[int, "Number of passengers"] = 1,
) -> dict:
    """Book a flight between two cities."""
    return {
        "confirmation": "ABC123",
        "route": f"{origin} -> {destination}",
        "date": date,
        "passengers": passengers,
    }
```

## Hosted Tools (Built-in)

```python
from agents import Agent, WebSearchTool, CodeInterpreterTool

agent = Agent(
    name="Researcher",
    instructions="Search the web and analyze data.",
    tools=[
        WebSearchTool(user_location={"type": "approximate", "city": "Helsinki"}),
        CodeInterpreterTool(tool_config={"type": "code_interpreter", "container": {"type": "auto"}}),
    ],
)
```

Hosted tools (run on OpenAI's servers):
- `WebSearchTool` - web search
- `FileSearchTool` - retrieval from OpenAI vector stores
- `CodeInterpreterTool` - sandboxed code execution (requires `tool_config`)
- `HostedMCPTool` - remote MCP server tools
- `ImageGenerationTool` - image generation

Local runtime tools (execute on your machine):
- `ComputerTool` - computer use / GUI automation
- `ShellTool` - shell command execution
- `LocalShellTool` - local shell commands
- `ApplyPatchTool` - apply file patches

## Agents as Tools

Use other agents as tools for orchestration:

```python
from agents import Agent, Runner

translator_es = Agent(
    name="SpanishTranslator",
    instructions="Translate to Spanish.",
)

translator_fr = Agent(
    name="FrenchTranslator",
    instructions="Translate to French.",
)

orchestrator = Agent(
    name="Orchestrator",
    instructions="Use translation tools as needed.",
    tools=[
        translator_es.as_tool(
            tool_name="translate_spanish",
            tool_description="Translate text to Spanish",
        ),
        translator_fr.as_tool(
            tool_name="translate_french",
            tool_description="Translate text to French",
        ),
    ],
)

result = await Runner.run(orchestrator, "Translate 'hello' to Spanish and French")
```

## Tool Guardrails

Use `@tool_input_guardrail` / `@tool_output_guardrail` and attach via `tool_input_guardrails=` / `tool_output_guardrails=` on `@function_tool`. Return `ToolGuardrailFunctionOutput` via `.allow()`, `.reject_content(message=...)`, or `.raise_exception()`.

```python
from agents import function_tool, tool_input_guardrail
from agents import ToolGuardrailFunctionOutput, ToolInputGuardrailData

@tool_input_guardrail
def validate_query(data: ToolInputGuardrailData) -> ToolGuardrailFunctionOutput:
    query = str(data.context.tool_arguments.get("query", ""))
    if len(query) < 3:
        return ToolGuardrailFunctionOutput.reject_content(message="Query too short")
    return ToolGuardrailFunctionOutput.allow()

@function_tool(tool_input_guardrails=[validate_query])
def search(query: Annotated[str, "Search query"]) -> list[str]:
    """Search for items."""
    return ["result1", "result2"]
```

## Forcing Tool Use

```python
from agents import Agent, ModelSettings

agent = Agent(
    name="ToolUser",
    instructions="Always use tools to answer.",
    tools=[get_weather, search_database],
    model_settings=ModelSettings(
        tool_choice="required",  # Force tool usage
    ),
)
```
