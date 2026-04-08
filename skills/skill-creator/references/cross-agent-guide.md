# Cross-Agent Compatibility Guide

Agent Skills are an open standard ([agentskills.io](https://agentskills.io))
supported by 30+ AI development tools. This guide covers platform-specific
discovery paths and compatibility considerations.

Read this when creating skills intended for use across multiple agent platforms.

## Contents
- Discovery paths per platform
- Universal rules
- Platform-specific notes

## Discovery paths

### Universal standard
`.agents/skills/` relative to project root (repo scope) or user home (user scope).

| Platform | Repo scope | User scope | Extra |
|----------|-----------|------------|-------|
| **Claude Code** | `.agents/skills/` | `~/.claude/skills/`, `~/.agents/skills/` | |
| **OpenAI Codex** | `.agents/skills/` | `~/.agents/skills/` | System: `~/.codex/skills/.system/` |
| **VS Code Copilot** | `.agents/skills/` | Per config | Agent mode required |
| **Cursor** | `.agents/skills/` | Per config | |
| **JetBrains Junie** | `.agents/skills/` | Per IDE config | |
| **Gemini CLI** | `.agents/skills/` | `~/.agents/skills/` | |
| **Roo Code** | `.agents/skills/` | Per config | |

### Our sync setup
Source of truth: `~/.agents/skills/`
Synced via `sync-skills.cmd` (Windows JUNCTIONs) to: `~/.claude/skills/`,
GitHub repo, Cursor rules. Codex reads `~/.agents/skills/` directly.

## Universal rules

1. **Forward slashes** in all paths: `scripts/helper.py` not `scripts\helper.py`
2. **State prerequisites**: "Install: pip install pypdf" not "Use the pdf library"
3. **Qualified MCP names**: `BigQuery:bigquery_schema` not just `bigquery_schema`
4. **Pin versions**: `uvx ruff@0.8.0`, `npx eslint@9.0.0`
5. **No interactive prompts**: Agents use non-interactive shells
6. **No Windows-only assumptions**: Use cross-platform paths and commands

## Platform-specific notes

### Claude Code
- `claude -p` available for trigger testing and description optimization
- Supports subagents for parallel test execution
- Skills in project `.agents/skills/` are repo-scoped

### OpenAI Codex
- Optional `agents/openai.yaml` for UI metadata and tool dependencies
- `$skill-creator` and `$skill-installer` built-in
- Both explicit (`/skills`, `$name`) and implicit (description-based) invocation
- Reads from repo → user → admin → system scope (in order)

### VS Code Copilot
- `/skills` lists available skills
- Tool-use reliability varies across models
- Agent mode must be selected

### Model considerations
- **Small models** (Haiku-tier): Need more explicit instructions
- **Medium models** (Sonnet-tier): Balance clarity and conciseness
- **Large models** (Opus-tier): Avoid over-explaining
- Target the smallest model you support for minimum detail level
