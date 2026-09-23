# 🧠 Claude Code AI Skills

> 24 skills and 2 agents for building AI applications with Next.js, Bun and modern UI tools.

## ⚡ Quick Start

Install in Claude Code:

```text
/plugin marketplace add laguagu/claude-code-nextjs-skills
/plugin install claude-code-nextjs-skills@laguagu
```

Then use `/claude-code-nextjs-skills:ai-app` to build an app or
`/claude-code-nextjs-skills:go` to check it in the browser. Relevant skills can also
activate from your request.

## 📋 Skills

### 🚀 App Generators

| Skill | Description |
|-------|-------------|
| [ai-app](skills/ai-app/) | Full-stack AI app (chatbots, agents, dashboards) |
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js 16 + shadcn/ui + bun |
| [nextjs-chatbot](skills/nextjs-chatbot/) | Web chatbot patterns (HITL, persistence, streaming) |

### 🎨 UI & Design

| Skill | Description |
|-------|-------------|
| [shadcn](skills/shadcn/) | shadcn/ui component management |
| [icons](skills/icons/) | Sourcing icons, flags, file-type badges and brand logos (Iconify, svgl) |
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
| [vercel-react-view-transitions](skills/vercel-react-view-transitions/) | React View Transitions and navigation motion |

### 🤖 AI SDKs

| Skill | Description |
|-------|-------------|
| [ai-sdk](skills/ai-sdk/) | Vercel AI SDK version discovery and documentation |
| [ai-sdk-6](skills/ai-sdk-6/) | AI SDK v6 (agents, streaming, tools) |
| [ai-sdk-7](skills/ai-sdk-7/) | AI SDK v7 (WorkflowAgent, harnesses, v6→v7 migration) |
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
| [hetzner-cloud](skills/hetzner-cloud/) | Hetzner Cloud infrastructure via the `hcloud` CLI |

## 🤖 Custom Agents

Example agents for common workflows. Installed with the Claude Code plugin; otherwise copy to
`.claude/agents/`.

| Agent | Description |
|-------|-------------|
| [code-simplifier](agents/code-simplifier.md) | Refines code for clarity (DRY/KISS/YAGNI) |
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

## 📥 Other Installation Options

- **Individual skills:** copy a skill folder and any referenced sibling skills to
  `.claude/skills/` (Claude Code) or `.agents/skills/` (Codex). User-wide locations
  are `~/.claude/skills/` and `~/.agents/skills/`.
- **Plugin-capable clients:** the root [plugin.json](plugin.json) uses
  [Agent Plugins format](https://agent-plugins.org/). Check your client's support
  and loading instructions; the format alone does not guarantee compatibility.
- **Local Claude Code trial:** clone this repo and run
  `claude --plugin-dir ./claude-code-nextjs-skills` from its parent directory.

## 🔧 MCP & Project Rules

[mcp.json](mcp.json) configures **Next.js DevTools** and the **AI Elements registry**.
Both plugin manifests use this single configuration. Optional Chrome DevTools MCP
setup is in the [browser testing skill](skills/chrome-devtools/SKILL.md).

[AGENTS.md](AGENTS.md) is an example of Next.js-generated agent rules plus the
custom rule `Always use bun, not npm`; [CLAUDE.md](CLAUDE.md) references it.

## 🔄 Updating

In Claude Code, run `/plugin marketplace update laguagu`, then
`/plugin update claude-code-nextjs-skills@laguagu`.

Maintainers: compare upstream updates before merging so local customizations and
licenses survive. Validate skills with
`uvx --from skills-ref agentskills validate <skill-folder>` and manifests with
`claude plugin validate .claude-plugin/plugin.json` and
`claude plugin validate .claude-plugin/marketplace.json`.

## 📚 See Also

[agents-best-practices](https://github.com/laguagu/agents-best-practices) — skill
auditing, creation and discovery across agent tools.

## 📄 License

MIT for original repository content. Bundled skills retain their upstream
licenses and attribution; see [Based On](#-based-on).
