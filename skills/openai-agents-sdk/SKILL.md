---
name: openai-agents-sdk
description: OpenAI Agents SDK (Python) development. Use when building AI agents, multi-agent handoffs, function tools, guardrails, sessions, streaming, or tracing with the `openai-agents` / `agents` Python package — including Azure OpenAI via LiteLLM. Triggers on imports from `agents`, uses of `Runner.run_sync`/`Runner.run_streamed`, `@function_tool`, `AgentOutputSchema`, `SQLiteSession`, or questions about the openai-agents-python SDK. Python only — not the TypeScript `@openai/agents` SDK.
---

# OpenAI Agents SDK (Python)

Use this skill when developing AI agents using OpenAI Agents SDK (`openai-agents` package).

## Quick Reference

### Installation

```bash
uv add openai-agents        # or `pip install openai-agents` outside a uv project
```

### Environment Variables

```bash
OPENAI_API_KEY=sk-...
```

Using Azure or another provider instead? See [agents.md](references/agents.md#other-providers-litellm) — don't hardcode provider env vars here, they vary and go stale.

### Basic Agent

```python
from agents import Agent, Runner

agent = Agent(
    name="Assistant",
    instructions="You are a helpful assistant.",
    model="gpt-5.6-sol",  # or "gpt-5.6-terra" / "gpt-5.6-luna" (cheaper tiers).
                          # "gpt-5.6" is an alias for gpt-5.6-sol. Verify
                          # current IDs from the model catalog.
)

# Synchronous
result = Runner.run_sync(agent, "Tell me a joke")
print(result.final_output)

# Asynchronous
result = await Runner.run(agent, "Tell me a joke")
```

Omitting `model=` uses the SDK's built-in default (currently `gpt-5.6-luna` with low-effort reasoning settings) — set it explicitly in production so an upstream default change cannot swap tiers silently.

### Key Patterns

| Pattern | Purpose |
|---------|---------|
| Basic Agent | Simple Q&A with instructions |
| Azure/LiteLLM | Azure OpenAI integration |
| AgentOutputSchema | Strict JSON validation with Pydantic |
| Function Tools | External actions (@function_tool) |
| Streaming | Real-time UI (Runner.run_streamed) |
| Handoffs | Specialized agents, delegation |
| Agents as Tools | Orchestration (agent.as_tool) |
| LLM as Judge | Iterative improvement loop |
| Guardrails | Input/output validation |
| Sessions | Automatic conversation history |
| Multi-Agent Pipeline | Multi-step workflows |
| Sandboxing | `SandboxAgent` — filesystem, shell and skills inside a local/Docker sandbox (beta) |
| Tracing | Built-in spans for runs, tools, handoffs and guardrails; pluggable processors |

The SDK has no separate `Subagent` class: express delegation with handoffs or
`agent.as_tool()`. For model-written tool orchestration, use
`ProgrammaticToolCallingTool` and verify its Responses-only constraints.

## Preferred: Live Docs via MCP

Model names and API details change frequently. When available, consult the **OpenAI Developer Docs MCP server** (`openaiDeveloperDocs`) before relying on the static references below.

Setup (Codex CLI):
```bash
codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp
```

Setup (Claude Code):
```bash
claude mcp add --transport http openaiDeveloperDocs https://developers.openai.com/mcp
```

Or config (`~/.codex/config.toml`, VS Code `.vscode/mcp.json`, Cursor `~/.cursor/mcp.json`):
```toml
[mcp_servers.openaiDeveloperDocs]
url = "https://developers.openai.com/mcp"
```

Key tools: `mcp__openaiDeveloperDocs__search_openai_docs`, `fetch_openai_doc`, `list_api_endpoints`, `get_openapi_spec`.

**Rules:** Cite fetched docs. Never speculate on field names, defaults, or current model IDs — fetch first. Keep quotes under 125 chars.

Fallback when MCP is unavailable: `https://developers.openai.com/api/docs/llms.txt` (plain-text index of all API docs; each entry has a `.md` twin at `/api/docs/<slug>.md`).

## Reference Documentation

Offline/quick-lookup snippets. Verify model names and API signatures against the MCP or docs when accuracy matters.

- [agents.md](references/agents.md) - read when choosing or wiring a model: default-model caveat, LiteLLM, native Azure client
- [tools.md](references/tools.md) - read when adding function tools, hosted tools, or agents-as-tools
- [structured-output.md](references/structured-output.md) - read when the output must be a Pydantic/dataclass shape (`AgentOutputSchema`, strict vs non-strict)
- [streaming.md](references/streaming.md) - read when streaming to a UI (event types, SSE with FastAPI)
- [handoffs.md](references/handoffs.md) - read when one agent delegates to another (handoff vs `as_tool`, input filters)
- [guardrails.md](references/guardrails.md) - read when validating input/output or gating tool calls
- [sessions.md](references/sessions.md) - read when conversation history must persist across requests (SQLite, SQLAlchemy, Redis, OpenAI Conversations)
- [patterns.md](references/patterns.md) - read for multi-agent pipelines, LLM-as-judge loops, tracing controls, `max_turns`, parallelization
- [sandbox.md](references/sandbox.md) - read when the agent must edit files or run commands in an isolated workspace (`SandboxAgent`, beta)

## Official Documentation

- **Docs:** https://openai.github.io/openai-agents-python/
- **Examples:** https://github.com/openai/openai-agents-python/tree/main/examples
- **Major update:** https://openai.com/index/the-next-evolution-of-the-agents-sdk/
- **Docs MCP setup:** https://developers.openai.com/learn/docs-mcp
- **Docs index (llms.txt):** https://developers.openai.com/api/docs/llms.txt
- **Current model IDs:** https://platform.openai.com/docs/models
