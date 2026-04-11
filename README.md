# 🧠 Claude Code AI Skills

> Skills for building AI applications, especially Next.js + bun runtime.

## ⚡ Quick Start

```bash
# Start a full-stack AI app
/ai-app

# Or use individual skills as needed
/ai-sdk-6              # AI agents & streaming
/postgres-semantic-search  # Vector/hybrid search
```

## 📋 Skills

### 🚀 App Generators

| Skill | Description |
|-------|-------------|
| [ai-app](skills/ai-app/) | Full-stack AI app (chatbots, agents, dashboards) |
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js 16 + shadcn/ui + bun |
| [nextjs-chatbot](skills/nextjs-chatbot/) | Production chatbot (HITL, persistence, GDPR) |

### 🎨 UI & Design

| Skill | Description |
|-------|-------------|
| [shadcn](skills/shadcn/) | shadcn/ui component management |
| [frontend-design](skills/frontend-design/) | Production-grade frontend interfaces |
| [web-design-guidelines](skills/web-design-guidelines/) | UI/UX review against Web Interface Guidelines |

### ⚡ Next.js

| Skill | Description |
|-------|-------------|
| [next-best-practices](skills/next-best-practices/) | RSC, async APIs, routing, optimization |
| [react-best-practices](skills/react-best-practices/) | React/Next.js performance optimization (Vercel) |
| [cache-components](skills/cache-components/) | Cache Components & PPR |
| [nextjs-seo](skills/nextjs-seo/) | SEO (metadata, sitemaps, JSON-LD) |

### 🤖 AI SDKs

| Skill | Description |
|-------|-------------|
| [ai-sdk](skills/ai-sdk/) | Vercel AI SDK general guide (official) |
| [ai-sdk-6](skills/ai-sdk-6/) | AI SDK v6 (agents, streaming, tools) |
| [ai-elements](skills/ai-elements/) | AI Elements UI components |
| [openai-agents-sdk](skills/openai-agents-sdk/) | OpenAI Agents SDK (Python) |

### 🗄️ Database & Search

| Skill | Description |
|-------|-------------|
| [postgres-semantic-search](skills/postgres-semantic-search/) | pgvector semantic & hybrid search |
| [supabase-postgres-best-practices](skills/supabase-postgres-best-practices/) | Postgres optimization (Supabase) |

### 🛠️ Tooling

| Skill | Description |
|-------|-------------|
| [skill-creator](skills/skill-creator/) | Create, test, and optimize custom skills (extended) |

## 🤖 Custom Agents

Example agents for common workflows. Copy to `.claude/agents/` to use.

| Agent | Description |
|-------|-------------|
| [code-simplifier](agents/code-simplifier.md) | Refines code for clarity (DRY/KISS/YAGNI) |
| [nextjs-reviewer](agents/nextjs-reviewer.md) | Review reports for Next.js projects |
| [e2e-tester](agents/e2e-tester.md) | E2E testing via DevTools MCP, Playwright, or Claude in Chrome |

## 📦 Based On

| Skill | Original Source | License |
|-------|-----------------|---------|
| [ai-sdk](skills/ai-sdk/) | [vercel/ai](https://github.com/vercel/ai/tree/main/skills) | Apache 2.0 |
| [cache-components](skills/cache-components/) | [vercel/next.js](https://github.com/vercel/next.js/tree/canary/.claude-plugin/plugins/cache-components/skills/cache-components) | MIT |
| [react-best-practices](skills/react-best-practices/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/SKILL.md) | - |
| [skill-creator](skills/skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (extended) | Apache 2.0 |
| [next-best-practices](skills/next-best-practices/) | [skills.sh/vercel-labs/next-skills](https://skills.sh/vercel-labs/next-skills/next-best-practices) | - |
| [web-design-guidelines](skills/web-design-guidelines/) | [skills.sh/vercel-labs/agent-skills](https://skills.sh/vercel-labs/agent-skills/web-design-guidelines) | - |
| [supabase-postgres-best-practices](skills/supabase-postgres-best-practices/) | [supabase/supabase](https://github.com/supabase/supabase) | Apache 2.0 |

## 📥 Installation

Copy or symlink skills to:

- **Claude Code**: `~/.claude/skills/` (global) or `.claude/skills/` (project)
- **Other agents** (Codex, Windsurf, Cursor): `~/.agents/skills/` or `.agents/skills/`

## 🔧 MCP Server

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

## 📚 See Also

- [agents-best-practices](https://github.com/laguagu/agents-best-practices) — `.agents`-first best practices, templates (AGENTS.md, CLAUDE.md, GEMINI.md, SKILL.md), and auditing tools for cross-platform agent skills

## 📄 License

MIT (this repository)

Some skills are extended from open source originals — see [Based On](#-based-on) for details.
