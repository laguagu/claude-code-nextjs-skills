# 🧠 Claude Code Next.js Skills

> Build production-ready AI applications with Claude Code skills.

## 🚀 Quick Start

```bash
# In Claude Code, just say:
/ai-app

# Or describe what you want:
"Create a chatbot with reasoning and file attachments"
"Build an agent dashboard with web search and calculator tools"
```

This creates a full-stack AI application with:
- Next.js 16 + React 19
- AI SDK 6 (Vercel)
- ai-elements UI components
- shadcn/ui + Tailwind
- bun runtime

## 📖 Continue Building with Skills

After scaffolding, use skill references for guidance:

```bash
/ai-elements         # UI component patterns
/ai-sdk-6            # Agent & streaming patterns
/nextjs-shadcn       # Next.js + shadcn patterns
/cache-components    # Caching & PPR
```

## 📦 All Skills

| Skill | Description | Source |
|-------|-------------|--------|
| [ai-app](skills/ai-app/) | Full-stack AI app generator (chatbots, agents) | |
| [ai-elements](skills/ai-elements/) | AI Elements UI components | |
| [ai-sdk-6](skills/ai-sdk-6/) | AI SDK v6 agents & streaming | |
| [openai-agents-sdk](skills/openai-agents-sdk/) | OpenAI Agents SDK (Python) | |
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js 16 + shadcn/ui + bun | |
| [cache-components](skills/cache-components/) | Next.js Cache Components & PPR | [vercel/next.js](https://github.com/vercel/next.js/tree/canary/.claude-plugin/plugins/cache-components/skills/cache-components) |
| [skill-creator](skills/skill-creator/) | Create skills, hooks, MCP configs | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) |

## 🔧 MCP Server

Includes [Next.js DevTools MCP](https://nextjs.org/docs/app/guides/mcp):

```json
// .mcp.json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

## 🚀 Installation

Copy or symlink skills to:

- **Global**: `~/.claude/skills/`
- **Project**: `.claude/skills/` in your project root

## 📖 Usage

```bash
/ai-app              # Create full-stack AI app
/ai-elements         # UI component patterns
/ai-sdk-6            # Vercel AI SDK patterns
/openai-agents-sdk   # OpenAI Agents SDK (Python)
/nextjs-shadcn       # Next.js + shadcn patterns
/cache-components    # Caching & PPR
/skill-creator       # Create custom skills
```

Skills also activate automatically based on context.

## 📄 License

MIT
