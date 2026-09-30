---
name: openai-agents-sdk
description: OpenAI Agents SDK (Python) development. Use when building AI agents, multi-agent handoffs, function tools, guardrails, sessions, streaming, or tracing with the `openai-agents` / `agents` Python package — including Azure OpenAI via LiteLLM. Triggers on imports from `agents`, uses of `Runner.run_sync`/`Runner.run_streamed`, `@function_tool`, `AgentOutputSchema`, `SQLiteSession`, or questions about the openai-agents-python SDK. Python only — not the TypeScript `@openai/agents` SDK.
---

# OpenAI Agents SDK for Python

Use this skill for `openai-agents` / `agents`, not the TypeScript SDK.
Resolve the installed package and its provider integrations before implementing
an API. Current [SDK documentation](https://openai.github.io/openai-agents-python/)
and a matching source tag take precedence over static examples.

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
- [Tools](references/tools.md): local/hosted execution and delegation.
- [Structured output](references/structured-output.md): schema and capability constraints.
- [Streaming](references/streaming.md): event types, failures and guardrails.
- [Handoffs](references/handoffs.md): control transfer and filtering.
- [Guardrails](references/guardrails.md): execution timing and coverage.
- [Sessions](references/sessions.md): history ownership and persistence.
- [Orchestration/tracing](references/patterns.md): run limits and observability.
- [Sandbox](references/sandbox.md): beta workspace execution and resume state.

Use the Developer Docs MCP if available for current OpenAI API/provider behavior;
use the Python SDK's own reference for SDK signatures. Read selected
[official examples](https://github.com/openai/openai-agents-python/tree/main/examples)
from a compatible tag, not a copied catalog of demos.

Verify changed tools, multi-turn history, approval/denial and failure recovery.
Run the project's checks; report missing provider access separately from verified
SDK behavior.
