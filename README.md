# 🧠 Claude Code Skills

Ready-to-use skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## 📦 Skills

| Skill | Description | Source |
|-------|-------------|--------|
| [cache-components](skills/cache-components/) | Next.js Cache Components & PPR | [vercel/next.js](https://github.com/vercel/next.js/tree/canary/.claude-plugin/plugins/cache-components/skills/cache-components) |
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js 16 + shadcn/ui | |
| [skill-creator](skills/skill-creator/) | Create skills, hooks, MCP configs (enhanced with ralph-loop, MCP, hooks) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) |
| [ai-sdk-6](skills/ai-sdk-6/) | AI SDK v6 agents & streaming | |

## 🔧 MCP Server

Includes [Next.js DevTools MCP](https://nextjs.org/docs/app/guides/mcp) configuration:

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
/cache-components
/nextjs-shadcn
/skill-creator
/ai-sdk-6
```

Skills also activate automatically based on context.

## 📄 License

MIT
