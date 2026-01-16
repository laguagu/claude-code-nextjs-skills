# Claude Code AI Skills

> Skills for building AI applications, especially Next.js + bun runtime.

## Quick Start

```bash
# Start a full-stack AI app
/ai-app

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
| [skill-creator](skills/skill-creator/) | Create custom skills |

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

MIT
