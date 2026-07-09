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
| [chrome-devtools](skills/chrome-devtools/) | Live browser inspection via Chrome DevTools MCP (DOM, console, network, performance) |
| [go](skills/go/) | Browser smoke test — verify recent UI changes work |

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
| [handoff](skills/handoff/) | Write a HANDOFF.md so a fresh agent can continue your work |

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
| [cache-components](skills/cache-components/) | [vercel/next.js](https://github.com/vercel/next.js/tree/canary/skills) | MIT |
| [react-best-practices](skills/react-best-practices/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/SKILL.md) | - |
| [skill-creator](skills/skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (extended) | Apache 2.0 |
| [next-best-practices](skills/next-best-practices/) | [skills.sh/vercel-labs/vercel-plugin](https://skills.sh/vercel-labs/vercel-plugin/next-best-practices) | - |
| [web-design-guidelines](skills/web-design-guidelines/) | [skills.sh/vercel-labs/agent-skills](https://skills.sh/vercel-labs/agent-skills/web-design-guidelines) | - |
| [supabase-postgres-best-practices](skills/supabase-postgres-best-practices/) | [supabase/agent-skills](https://github.com/supabase/agent-skills/tree/main/skills/supabase-postgres-best-practices) | MIT |
| [chrome-devtools](skills/chrome-devtools/) | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills/blob/main/skills/browser-testing-with-devtools/SKILL.md) | - |
| [shadcn](skills/shadcn/) | [shadcn/ui](https://ui.shadcn.com/docs/skills) | MIT |

## 🔄 Updating

Skills under [Based On](#-based-on) drift as their upstreams change. To refresh one: fetch the
upstream folder, `diff` it against the local copy, and copy over the changed content files — but
keep the local `SKILL.md` frontmatter, since `name`/`description` and cross-skill references are
often customized. Skip a blind `npx skills update`: there is no lock file and some folders are
renamed from upstream.

## 📥 Installation

Copy or symlink skills to:

- **Claude Code**: `~/.claude/skills/` (global) or `.claude/skills/` (project)
- **Other agents** (Codex, Windsurf, Cursor): `~/.agents/skills/` or `.agents/skills/`

## 🔧 MCP Servers

Recommended MCP servers that pair with these skills:

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    },
    "chrome-devtools": {
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest"]
    },
    "ai-elements": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://registry.ai-sdk.dev/api/mcp"]
    }
  }
}
```

This repo's own [`.mcp.json`](.mcp.json) already wires up `next-devtools` and `ai-elements`; `chrome-devtools` is optional and shown here for reference.

- [Next.js DevTools MCP](https://nextjs.org/docs/app/guides/mcp) — pairs with `next-best-practices`, `e2e-tester`
- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp) — pairs with `chrome-devtools`, `go`, `e2e-tester`. Install via CLI: `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest`
- AI Elements registry MCP — pairs with `ai-elements`, `ai-app`, `nextjs-chatbot`

## 📚 See Also

- [agents-best-practices](https://github.com/laguagu/agents-best-practices) — `.agents`-first best practices, auditing (improving-skills), skill creation (skill-creator), and discovery (skill-finder) for cross-platform agent skills

## 📄 License

MIT (this repository)

Some skills are extended from open source originals — see [Based On](#-based-on) for details.
