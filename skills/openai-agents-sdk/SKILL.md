---
name: openai-agents-sdk
description: OpenAI Agents SDK (Python) development. Use when building AI agents, multi-agent handoffs, function tools, guardrails, sessions, streaming, or tracing with the `openai-agents` / `agents` Python package — including Azure OpenAI via LiteLLM. Triggers on imports from `agents`, uses of `Runner.run_sync`/`Runner.run_streamed`, `@function_tool`, `AgentOutputSchema`, `SQLiteSession`, or questions about the openai-agents-python SDK. Python only — not the TypeScript `@openai/agents` SDK.
---

# OpenAI Agents SDK for Python

Use this skill for `openai-agents` / `agents`, not the TypeScript SDK.
Resolve the installed package and its provider integrations before implementing
an API. Current [SDK documentation](https://openai.github.io/openai-agents-python/)
and a matching source tag take precedence over static examples.

Choose a model from the current [OpenAI model catalog](https://developers.openai.com/api/docs/models)
and [model-selection guide](https://developers.openai.com/api/docs/guides/model-selection).
Check the selected model's tools, reasoning settings and provider availability;
an SDK fallback or a demo ID is not a permanent recommendation.

The wheel ships no docs. Offline, read the installed source: the version from
`importlib.metadata.version("openai-agents")`, public exports in
`agents/__init__.py`, docstrings and types in the package directory
(`python -c "import agents; print(agents.__file__)"`). The documentation
source is `docs/` at repository tag `v<version>`.

## Core shape

`Runner.run_sync` raises inside a running event loop (async handlers and
notebooks); use `await Runner.run(...)`. `Runner.run_streamed(...)` itself
is not awaited; consume its `stream_events()` async iterator to completion.

Checked with openai-agents 0.22.3; confirm names in the installed source for
another version:

```python
import asyncio
from pydantic import BaseModel
from agents import Agent, ModelSettings, Runner, SQLiteSession, function_tool
from openai.types.shared import Reasoning

class OrderAnswer(BaseModel):
    order_id: str
    status: str
    reply: str

@function_tool
def get_order_status(order_id: str) -> str:
    """Return an order's shipping status.

    Args:
        order_id: Order ID given by the customer.
    """
    return f"{order_id}: shipped"  # authorize and read the app's data here

support = Agent(
    name="Support",
    instructions="Answer order questions. Use get_order_status for order data.",
    model="gpt-6.1-sol",  # example API ID; use the project's configured model
    model_settings=ModelSettings(reasoning=Reasoning(effort="medium")),
    tools=[get_order_status],
    output_type=OrderAnswer,
)
# A manager keeps control with tools=[order_tool]; handoffs=[support] transfers it.
order_tool = support.as_tool("order_support", "Answer an order question.")

async def main() -> None:
    session = SQLiteSession("user-123", "conversations.db")  # ID owned by the signed-in user
    result = await Runner.run(support, "Where is order A-17?", session=session)
    answer: OrderAnswer = result.final_output  # validated OrderAnswer instance
    print(answer.status, answer.reply)

asyncio.run(main())
```

The example uses Responses (the SDK's default API). [GPT-6.1 Sol](https://developers.openai.com/api/docs/models/gpt-6.1-sol)
requires Responses for tool calling and does not support `none` or `minimal`
reasoning effort. Model availability/live responses were not tested by the
offline SDK check.

## Integration decisions

- Keep the project's provider, model and storage unless the task requires a
  change. Verify model IDs/capabilities in provider configuration or live docs.
  SDK model/settings defaults may change; configure product-critical choices
  explicitly.
- Use native provider/client support when it fits. LiteLLM/Any-LLM are optional
  integrations with their own compatibility and settings behavior.
- Choose handoffs when a specialist takes over, or `agent.as_tool()` when the
  manager should continue after delegated work. A fixed pipeline does not need
  extra agents merely to implement ordinary control flow.
- Authorize side effects in tools. Agent instructions, output schemas and
  guardrails do not replace authorization or idempotency.
- Decide history ownership, approval/resume and tracing data policy before
  exposing a multi-turn agent to untrusted clients.

## Read for the feature

- [Agents/providers](references/agents.md): model defaults, Azure and adapters.
- [Tools](references/tools.md): local/hosted execution, delegation and approval/resume.
- [Structured output](references/structured-output.md): schema and capability constraints.
- [Streaming](references/streaming.md): event types, failures and guardrails.
- [Handoffs](references/handoffs.md): control transfer and filtering.
- [Guardrails](references/guardrails.md): execution timing and coverage.
- [Sessions](references/sessions.md): history ownership and persistence.
- [Orchestration/tracing](references/patterns.md): run limits and observability.
- [Sandbox](references/sandbox.md): beta workspace execution and resume state.

Use the OpenAI Developer Docs MCP (`https://developers.openai.com/mcp`) if
available for current OpenAI API/provider behavior, or its plain-text index
`https://developers.openai.com/api/docs/llms.txt`; use the Python SDK's own
reference for SDK signatures. Read selected
[official examples](https://github.com/openai/openai-agents-python/tree/main/examples)
from a compatible tag, not a copied catalog of demos.

## Verification

Verify changed tools, multi-turn history, approval/denial and failure recovery.
Use installed `agents.testing` (verified in 0.22.3) for offline orchestration:
`ScriptedModel`, `ModelStep`, `assistant_message`, `function_call` and
`model.assert_complete()`, with `RunConfig(tracing_disabled=True)`; assigning
`agent.model = ScriptedModel([...])` runs the core shape offline. Run the
project's checks; report missing provider access separately from verified SDK
behavior.
