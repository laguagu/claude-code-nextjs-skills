# Claude Code AI Skills

> Skills for building AI applications, especially Next.js + bun runtime.

## Quick Start

```bash
# Start a full-stack AI app
/ai-app

# Start autonomous Ralph Loop for complex apps
/ralph-loop:ralph-loop "/ai-app @spec/PLAN.md build this app" --max-iterations 50 --completion-promise "DONE"

# Or use individual skills as needed
/ai-sdk-6              # AI agents & streaming
/postgres-semantic-search  # Vector/hybrid search
```

## Skills

### 🚀 App Development

| Skill | Description |
|-------|-------------|
| [ai-app](skills/ai-app/) | Full-stack AI app (chatbots, agents, dashboards) |
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js 16 + shadcn/ui + bun |
| [cache-components](skills/cache-components/) | Next.js Cache Components & PPR |
| [nextjs-seo](skills/nextjs-seo/) | SEO optimization (metadata, sitemaps, JSON-LD) |

### 🤖 AI SDKs

| Skill | Description |
|-------|-------------|
| [ai-sdk-6](skills/ai-sdk-6/) | Vercel AI SDK v6 (agents, streaming, tools) |
| [ai-elements](skills/ai-elements/) | AI Elements UI components |
| [openai-agents-sdk](skills/openai-agents-sdk/) | OpenAI Agents SDK (Python) |

### 🗄️ Data & Search

| Skill | Description |
|-------|-------------|
| [postgres-semantic-search](skills/postgres-semantic-search/) | pgvector semantic & hybrid search |

### 🛠️ Meta

| Skill | Description |
|-------|-------------|
| [skill-creator](skills/skill-creator/) | Create custom skills - includes [Ralph Loop](skills/skill-creator/references/ralph-loop.md) docs |

### 📦 Based On

| Skill | Original Source | License |
|-------|-----------------|---------|
| [cache-components](skills/cache-components/) | [vercel/next.js](https://github.com/vercel/next.js/tree/canary/.claude-plugin/plugins/cache-components/skills/cache-components) | MIT |
| [react-best-practices](skills/react-best-practices/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/SKILL.md) | - |
| [skill-creator](skills/skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (extended) | Apache 2.0 |

## Custom Agents

Example agents for common workflows. Copy to `.claude/agents/` to use.

| Agent | Description |
|-------|-------------|
| [code-simplifier](agents/code-simplifier.md) | Refines code for clarity (DRY/KISS/YAGNI) after coding sessions |
| [nextjs-reviewer](agents/nextjs-reviewer.md) | Generates review reports for Next.js projects |

See [sub-agents reference](skills/skill-creator/references/sub-agents.md) for creating custom agents.

## Installation

Copy or symlink skills to:

- **Global**: `~/.claude/skills/`
- **Project**: `.claude/skills/`

## MCP Server

Includes [Next.js DevTools MCP](https://nextjs.org/docs/app/guides/mcp):

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

## License

MIT (this repository)

Some skills are extended from open source originals:
- `skill-creator`: Extended from [anthropics/skills](https://github.com/anthropics/skills) (Apache 2.0)
- `cache-components`: From [vercel/next.js](https://github.com/vercel/next.js) (MIT)
