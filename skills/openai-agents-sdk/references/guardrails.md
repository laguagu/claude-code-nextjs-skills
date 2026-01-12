# Guardrails

## Input Guardrails

Validate and filter input before the agent processes it:

```python
from agents import Agent, Runner, input_guardrail
from agents import GuardrailFunctionOutput, RunContextWrapper

@input_guardrail
async def check_appropriate(
    ctx: RunContextWrapper, agent: Agent, input: str
) -> GuardrailFunctionOutput:
    # Check input for inappropriate content
    is_inappropriate = "bad_word" in input.lower()
    return GuardrailFunctionOutput(
        tripwire_triggered=is_inappropriate,
        output_info="Inappropriate content detected" if is_inappropriate else None,
    )

@input_guardrail
async def check_length(
    ctx: RunContextWrapper, agent: Agent, input: str
) -> GuardrailFunctionOutput:
    if len(input) > 10000:
        return GuardrailFunctionOutput(
            tripwire_triggered=True,
            output_info="Input too long (max 10000 characters)",
        )
    return GuardrailFunctionOutput(tripwire_triggered=False)

agent = Agent(
    name="SafeAgent",
    instructions="Be helpful.",
    input_guardrails=[check_appropriate, check_length],
)
```

## Output Guardrails

Validate agent output before returning:

```python
from agents import Agent, output_guardrail
from agents import GuardrailFunctionOutput, RunContextWrapper

@output_guardrail
async def check_no_pii(
    ctx: RunContextWrapper, agent: Agent, output: str
) -> GuardrailFunctionOutput:
    # Check for potential PII in output
    import re

    # Simple email pattern check
    has_email = bool(re.search(r'\b[\w.-]+@[\w.-]+\.\w+\b', output))
    # Simple phone pattern check
    has_phone = bool(re.search(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', output))

    if has_email or has_phone:
        return GuardrailFunctionOutput(
            tripwire_triggered=True,
            output_info="Output contains potential PII",
        )
    return GuardrailFunctionOutput(tripwire_triggered=False)

agent = Agent(
    name="PIISafeAgent",
    instructions="Help users with their questions.",
    output_guardrails=[check_no_pii],
)
```

## Guardrail with Context

```python
from agents import Agent, input_guardrail
from agents import GuardrailFunctionOutput, RunContextWrapper

@input_guardrail
async def check_user_permissions(
    ctx: RunContextWrapper[dict], agent: Agent, input: str
) -> GuardrailFunctionOutput:
    user_role = ctx.context.get("user_role", "guest")

    # Check if user can access admin features
    if "admin" in input.lower() and user_role != "admin":
        return GuardrailFunctionOutput(
            tripwire_triggered=True,
            output_info="Admin access not permitted for your role",
        )
    return GuardrailFunctionOutput(tripwire_triggered=False)

agent = Agent(
    name="RoleBasedAgent",
    instructions="Help users based on their role.",
    input_guardrails=[check_user_permissions],
)

# User without admin access
result = await Runner.run(
    agent,
    "Show me admin settings",
    context={"user_role": "user"},
)
# -> Guardrail triggered
```

## Tool Guardrails

Validate tool inputs before execution:

```python
from agents import function_tool, tool_guardrail
from agents import ToolGuardrailFunctionOutput, RunContextWrapper
from typing import Annotated

@tool_guardrail
async def validate_file_path(
    ctx: RunContextWrapper, agent: Agent, tool_input: dict
) -> ToolGuardrailFunctionOutput:
    path = tool_input.get("file_path", "")

    # Block access to sensitive directories
    forbidden = ["/etc", "/root", "~/.ssh"]
    for forbidden_path in forbidden:
        if path.startswith(forbidden_path):
            return ToolGuardrailFunctionOutput(
                tripwire_triggered=True,
                output_info=f"Access to {forbidden_path} not allowed",
            )
    return ToolGuardrailFunctionOutput(tripwire_triggered=False)

@function_tool(guardrails=[validate_file_path])
def read_file(file_path: Annotated[str, "Path to file"]) -> str:
    """Read contents of a file."""
    with open(file_path) as f:
        return f.read()
```

## Handling Guardrail Errors

```python
from agents import Agent, Runner, InputGuardrailTripwireTriggered

agent = Agent(
    name="SafeBot",
    instructions="Be helpful.",
    input_guardrails=[check_appropriate],
)

try:
    result = await Runner.run(agent, "Some bad_word input")
except InputGuardrailTripwireTriggered as e:
    print(f"Input blocked: {e.guardrail_result.output_info}")
```

## GuardrailFunctionOutput Fields

| Field | Description |
|-------|-------------|
| `tripwire_triggered` | True if guardrail should block |
| `output_info` | Human-readable explanation |
