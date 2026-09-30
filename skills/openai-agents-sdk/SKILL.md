---
name: openai-agents-sdk
description: OpenAI Agents SDK (Python) development. Use when building AI agents, multi-agent handoffs, function tools, guardrails, sessions, streaming, or tracing with the `openai-agents` / `agents` Python package — including Azure OpenAI via LiteLLM. Triggers on imports from `agents`, uses of `Runner.run_sync`/`Runner.run_streamed`, `@function_tool`, `AgentOutputSchema`, `SQLiteSession`, or questions about the openai-agents-python SDK. Python only — not the TypeScript `@openai/agents` SDK.
---

# OpenAI Agents SDK for Python

Use this skill for `openai-agents` / `agents`, not the TypeScript SDK.

## Sources, in order

1. The installed package matches the project and needs no network:
   `python -c "import agents; print(agents.__version__, agents.__file__)"`, then
   read that source, `help(agents.Runner.run)` and `agents.__all__`.
2. The official docs (https://openai.github.io/openai-agents-python/). Breaking
   changes per minor version: `/release/`. Examples: `examples/` in
   https://github.com/openai/openai-agents-python at the installed version's tag.
3. The facts below, checked against 0.22.3 (2026-09). Sources 1 and 2 win when
   they disagree.

## Minimal run

```python
from agents import Agent, Runner, function_tool

@function_tool
def order_status(order_id: str) -> str:
    """Return the status of an order."""
    ...

agent = Agent(name="Support", instructions="...", model="<configured model>", tools=[order_status])
result = await Runner.run(agent, "Where is order 42?")
print(result.final_output)
```

## Gotchas (0.22.x)

| Area | Fact |
| --- | --- |
| Default model | Omitting `model` uses the SDK default (`gpt-5.6-luna` since 0.20; `OPENAI_DEFAULT_MODEL` overrides). Only `gpt-5*` names get tuned `ModelSettings`; any other name, such as a custom Azure deployment name, gets bare `ModelSettings()`. |
| `run_sync` | Raises `RuntimeError` inside a running event loop (async handlers, notebooks). Use `await Runner.run(...)`. |
| Tool exceptions | Do not raise: the model gets "An error occurred while running the tool… Error: <message>". `failure_error_function=None` re-raises; a custom function controls the text. |
| Input guardrails | Run in parallel with the agent by default, so tools can run before a tripwire. `@input_guardrail(run_in_parallel=False)` blocks first. Only the first agent's input and the final agent's output guardrails run. |
| History owner | `session=` combined with `conversation_id`/`previous_response_id`/`auto_previous_response_id` raises `UserError`, as do output guardrails with server-managed history on Responses models. |
| Streaming | Drain `result.stream_events()` to the end: session writes, approvals and `final_output` settle after the last token. Errors raise from the loop. |
| Tracing | On by default; uploads model and tool inputs/outputs to OpenAI. Without an OpenAI key (Azure, LiteLLM) uploads fail with 401: `set_tracing_disabled(True)` or `OPENAI_AGENTS_DISABLE_TRACING=1`. |
| LiteLLM | `openai-agents` needs `openai>=3`; LiteLLM 1.84+ pins `openai<3`, so the resolver lands on 1.83.x. An Azure deployment name LiteLLM does not recognize rejects `reasoning_effort` unless allowed explicitly ([agents.md](references/agents.md)). |
| `@tool` | `from agents.decorators import tool` (0.19+) is an alias of `function_tool`; current docs use it. |

## Integration decisions

- Keep the project's provider, model and storage unless the task requires a
  change. Configure product-critical model and settings explicitly.
- Use native provider/client support when it fits; LiteLLM/Any-LLM are beta
  adapters.
- Choose handoffs when a specialist takes over, or `agent.as_tool()` when the
  manager should continue after delegated work. A fixed pipeline needs ordinary
  code, not extra agents.
- Authorize side effects in tools. Instructions, output schemas and guardrails
  do not replace authorization or idempotency.
- Decide history ownership, approval/resume and tracing data policy before
  exposing a multi-turn agent to untrusted clients.

## Read for the feature

- [Agents/providers](references/agents.md): default model, Azure, LiteLLM.
- [Tools](references/tools.md): function/hosted tools, errors, approvals.
- [Structured output](references/structured-output.md): strict schemas, model settings.
- [Streaming](references/streaming.md): event types, cancellation, failures.
- [Handoffs](references/handoffs.md): control transfer and history filtering.
- [Guardrails](references/guardrails.md): timing, coverage, tripwires.
- [Sessions](references/sessions.md): history owners and stores.
- [Orchestration/tracing](references/patterns.md): run limits and observability.
- [Sandbox](references/sandbox.md): beta workspace execution.

## Done

Test orchestration offline with `agents.testing` (0.21+): `ScriptedModel`,
`assistant_message`, `function_call(name, args, call_id=...)`,
`model.assert_complete()` and `RunConfig(tracing_disabled=True)`. Cover changed
tools, multi-turn history, approval/denial, guardrail tripwires and failure
recovery, then run the project's checks. Report missing provider access
separately from verified SDK behavior.
