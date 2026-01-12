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

| Skill | Description |
|-------|-------------|
| [ai-app](skills/ai-app/) | 🚀 Full-stack AI app generator |
| [ai-elements](skills/ai-elements/) | 🎨 AI Elements UI components |
| [ai-sdk-6](skills/ai-sdk-6/) | 🤖 AI SDK v6 agents & streaming |
| [nextjs-shadcn](skills/nextjs-shadcn/) | ⚡ Next.js 16 + shadcn/ui |
| [cache-components](skills/cache-components/) | 📦 Cache Components & PPR |
| [skill-creator](skills/skill-creator/) | 🛠️ Create custom skills |

## 🔧 Installation

Copy skills to your Claude Code skills directory:

```bash
# Global (all projects)
cp -r skills/* ~/.claude/skills/

# Or project-specific
cp -r skills/* .claude/skills/
```

## 🔌 MCP Server

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

## 📄 License

MIT
