# Handoffs

## Basic Handoffs

Handoffs allow agents to delegate tasks to specialized agents:

```python
from agents import Agent, handoff

billing_agent = Agent(
    name="BillingAgent",
    instructions="Handle billing questions. You can help with invoices, payments, and subscriptions.",
)

support_agent = Agent(
    name="SupportAgent",
    instructions="Handle general support. Handoff billing questions to the billing agent.",
    handoffs=[billing_agent],
)

# LLM automatically decides when to delegate to another agent
result = await Runner.run(support_agent, "I have a question about my invoice")
```

## Multiple Handoffs

```python
billing_agent = Agent(
    name="BillingAgent",
    instructions="Handle billing and payment questions.",
)

technical_agent = Agent(
    name="TechnicalAgent",
    instructions="Handle technical issues and troubleshooting.",
)

sales_agent = Agent(
    name="SalesAgent",
    instructions="Handle sales inquiries and pricing.",
)

triage_agent = Agent(
    name="TriageAgent",
    instructions="""You are a customer service triage agent.
    Route customers to the appropriate specialist:
    - Billing questions -> BillingAgent
    - Technical issues -> TechnicalAgent
    - Sales/pricing -> SalesAgent
    """,
    handoffs=[billing_agent, technical_agent, sales_agent],
)

result = await Runner.run(triage_agent, "My app keeps crashing")
# -> Delegates to TechnicalAgent
```

## Handoff with Context

```python
from agents import Agent, handoff, RunContextWrapper

def escalation_instructions(
    ctx: RunContextWrapper[dict], agent: Agent[dict]
) -> str:
    priority = ctx.context.get("priority", "normal")
    return f"""You are handling an escalated case.
    Priority level: {priority}
    Be thorough and professional."""

escalation_agent = Agent(
    name="EscalationAgent",
    instructions=escalation_instructions,
)

support_agent = Agent(
    name="SupportAgent",
    instructions="Handle support. Escalate complex issues.",
    handoffs=[escalation_agent],
)

result = await Runner.run(
    support_agent,
    "This is urgent, I need help immediately!",
    context={"priority": "high"},
)
```

## Handoff vs Agents as Tools

| Feature | Handoffs | Agents as Tools |
|---------|----------|-----------------|
| Control flow | LLM decides when to delegate | Parent agent calls child explicitly |
| Return | Child agent takes over | Returns result to parent |
| Use case | Specialized routing | Orchestration, parallel tasks |
| Conversation | Child continues conversation | Parent continues after tool result |

### Handoff Example

```python
# Child takes over the conversation
support_agent = Agent(
    name="Support",
    handoffs=[billing_agent],  # Billing agent takes over
)
```

### Agent as Tool Example

```python
# Parent stays in control
orchestrator = Agent(
    name="Orchestrator",
    tools=[
        billing_agent.as_tool(
            tool_name="check_billing",
            tool_description="Get billing info",
        ),
    ],
)
```

## Message Filtering

Control what messages are passed during handoff:

An input filter receives and returns `HandoffInputData` (fields: `input_history`, `pre_handoff_items`, `new_items`):

```python
from agents import Agent, handoff
from agents.handoffs import HandoffInputData

def filter_messages(data: HandoffInputData) -> HandoffInputData:
    # Only keep last 5 items of the input history
    history = data.input_history
    if isinstance(history, tuple):
        history = history[-5:]
    return HandoffInputData(
        input_history=history,
        pre_handoff_items=data.pre_handoff_items,
        new_items=data.new_items,
    )

specialist = Agent(
    name="Specialist",
    instructions="Handle specialized tasks.",
)

agent = Agent(
    name="Router",
    instructions="Route to specialist when needed.",
    handoffs=[
        handoff(
            agent=specialist,
            input_filter=filter_messages,
        ),
    ],
)
```

Ready-made filters are available in `agents.extensions.handoff_filters`, e.g. `handoff_filters.remove_all_tools` to strip tool calls from the handed-off history.
