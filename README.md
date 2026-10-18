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
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js + shadcn/ui with deliberate typography, backgrounds, and design-system lint via [@shadcn/lint](https://github.com/shadcn-ui/lint) |
| [nextjs-chatbot](skills/nextjs-chatbot/) | Web chatbot patterns (HITL, persistence, streaming) |

### 🎨 UI & Design

| Skill | Description |
|-------|-------------|
| [shadcn](skills/shadcn/) | shadcn/ui component management |
| [icons](skills/icons/) | Sourcing icons, flags, file-type badges and brand logos (Iconify, svgl) |
| [frontend-design](skills/frontend-design/) | Distinctive visual direction and typography for new or reshaped UI |
| [web-design-guidelines](skills/web-design-guidelines/) | UI/UX review against Web Interface Guidelines |
| [chrome-devtools](skills/chrome-devtools/) | Live browser inspection via Chrome DevTools MCP (DOM, console, network, performance) |
| [go](skills/go/) | Browser smoke test — verify recent UI changes work |

### ⚡ Next.js

| Skill | Description |
|-------|-------------|
| [next-best-practices](skills/next-best-practices/) | Installed-version docs for routing, RSC and Next.js integration |
| [react-best-practices](skills/react-best-practices/) | React/Next.js performance optimization (Vercel) |
| [cache-components](skills/cache-components/) | Cache Components, freshness, invalidation and isolation |
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
| [supabase-postgres-best-practices](skills/supabase-postgres-best-practices/) | Postgres schema, migrations, RLS and query performance (Supabase) |

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
| [code-simplifier](agents/code-simplifier.md) | Simplifies recently changed code while preserving behavior |
| [e2e-tester](agents/e2e-tester.md) | Tests real user flows in the browser and fixes verified defects |

## 📦 Based On

| Skill | Original Source | License |
|-------|-----------------|---------|
| [ai-sdk](skills/ai-sdk/) | [vercel/ai](https://github.com/vercel/ai/tree/main/skills) | Apache 2.0 |
| [cache-components](skills/cache-components/) | [vercel-labs/next-skills](https://github.com/vercel-labs/next-skills) (skills moved to [vercel/next.js](https://github.com/vercel/next.js/tree/canary/skills) in June 2026; maintained locally) | - |
| [react-best-practices](skills/react-best-practices/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/SKILL.md) | MIT |
| [skill-creator](skills/skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (extended) | Apache 2.0 |
| [next-best-practices](skills/next-best-practices/) | [vercel-labs/next-skills](https://github.com/vercel-labs/next-skills) (skills moved to [vercel/next.js](https://github.com/vercel/next.js/tree/canary/skills) in June 2026; maintained locally) | - |
| [web-design-guidelines](skills/web-design-guidelines/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) | MIT |
| [supabase-postgres-best-practices](skills/supabase-postgres-best-practices/) | [supabase/agent-skills](https://github.com/supabase/agent-skills/tree/main/skills/supabase-postgres-best-practices) | MIT |
| [chrome-devtools](skills/chrome-devtools/) | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills/blob/main/skills/browser-testing-with-devtools/SKILL.md) | MIT |
| [shadcn](skills/shadcn/) | [shadcn/ui](https://ui.shadcn.com/docs/skills) | MIT |
| [ai-elements](skills/ai-elements/) | [vercel/ai-elements](https://github.com/vercel/ai-elements/tree/main/skills/ai-elements) | Apache 2.0 |
| [frontend-design](skills/frontend-design/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Apache 2.0 |
| [vercel-react-view-transitions](skills/vercel-react-view-transitions/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-view-transitions) | MIT |

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

[AGENTS.md](AGENTS.md) holds the rules for working on this repository and
[CLAUDE.md](CLAUDE.md) imports it; installing the plugin does not load them as
project context.

[examples/global-agents.md](examples/global-agents.md) is a user-wide instruction
file for long autonomous runs: when to keep going, when to stop, and how to report.

## 🔄 Updating

In a shell, run `claude plugin marketplace update laguagu`, then
`claude plugin update claude-code-nextjs-skills@laguagu`.

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
