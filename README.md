# 🧠 Claude Code AI Skills

> 24 skills and 2 agents for building AI applications with Next.js, Bun and modern UI tools.

## ⚡ Quick Start

Install in Claude Code:

```text
/plugin marketplace add laguagu/claude-code-nextjs-skills
/plugin install nextjs-ai-skills@laguagu
```

Then use `/nextjs-ai-skills:nextjs-shadcn` to build an app or
`/nextjs-ai-skills:go` to check it in the browser. Relevant skills also activate
from your request.

To update, run `claude plugin marketplace update laguagu` and then
`claude plugin update nextjs-ai-skills@laguagu` in a shell. If you installed the
plugin under its old name `claude-code-nextjs-skills`, uninstall that and install
`nextjs-ai-skills@laguagu`.

## 📋 Skills

### 🚀 App Generators

| Skill | Description |
|-------|-------------|
| [nextjs-shadcn](skills/nextjs-shadcn/) | Next.js + shadcn/ui with deliberate typography, backgrounds, and design-system lint via [@shadcn/lint](https://github.com/shadcn-ui/lint) |
| [nextjs-chatbot](skills/nextjs-chatbot/) | Web chatbot patterns (HITL, persistence, streaming) |

### 🎨 UI & Design

| Skill | Description |
|-------|-------------|
| [shadcn](skills/shadcn/) | shadcn/ui component management |
| [icons](skills/icons/) | Sourcing icons, flags, file-type badges and brand logos (Iconify, svgl) |
| [frontend-design](skills/frontend-design/) | Distinctive visual direction and typography for new or reshaped UI |
| [web-design-guidelines](skills/web-design-guidelines/) | UI/UX review against Web Interface Guidelines |
| [go](skills/go/) | Browser smoke test — verify recent UI changes work |

### ⚡ Next.js

| Skill | Description |
|-------|-------------|
| [nextjs-seo](skills/nextjs-seo/) | SEO (metadata, sitemaps, JSON-LD) |
| [vercel-react-view-transitions](skills/vercel-react-view-transitions/) | React View Transitions and navigation motion |

### 🤖 AI SDKs

| Skill | Description |
|-------|-------------|
| [ai-sdk](skills/ai-sdk/) | Vercel AI SDK version discovery and documentation |
| [ai-sdk-6](skills/ai-sdk-6/) | AI SDK v6 (agents, streaming, tools) |
| [ai-sdk-7](skills/ai-sdk-7/) | AI SDK v7 (WorkflowAgent, harnesses, v6→v7 migration) |
| [openai-agents-sdk](skills/openai-agents-sdk/) | OpenAI Agents SDK (Python) |

### 🗄️ Database & Search

| Skill | Description |
|-------|-------------|
| [postgres-semantic-search](skills/postgres-semantic-search/) | pgvector semantic & hybrid search |

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

## 🔧 Also Included

- [mcp.json](mcp.json) starts the
  [Next.js DevTools MCP](https://github.com/vercel/next-devtools-mcp) server with
  the plugin. For Chrome DevTools MCP, follow its
  [setup guide](https://github.com/ChromeDevTools/chrome-devtools-mcp).
- [examples/global-agents.md](examples/global-agents.md) is an example user-wide
  instruction file for long autonomous agent runs.

## 📥 Without the Plugin

Copy a skill folder, and any sibling skill it references, to `.claude/skills/`
(Claude Code) or `.agents/skills/` (Codex); for all projects, use
`~/.claude/skills/` or `~/.agents/skills/`. Clients that support the
[Agent Plugins format](https://agent-plugins.org/) can read the root
[plugin.json](plugin.json).

## 📦 Based On

| Skill | Original Source | License |
|-------|-----------------|---------|
| [ai-sdk](skills/ai-sdk/) | [vercel/ai](https://github.com/vercel/ai/tree/main/skills) | Apache 2.0 |
| [skill-creator](skills/skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (extended) | Apache 2.0 |
| [web-design-guidelines](skills/web-design-guidelines/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) | MIT |
| [shadcn](skills/shadcn/) | [shadcn/ui](https://ui.shadcn.com/docs/skills) | MIT |
| [frontend-design](skills/frontend-design/) | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Apache 2.0 |
| [vercel-react-view-transitions](skills/vercel-react-view-transitions/) | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-view-transitions) | MIT |

Removed in 1.1.0: `ai-app`, `ai-elements` (deprecated upstream), `cache-components`, `chrome-devtools`, `next-best-practices`, `react-best-practices` and `supabase-postgres-best-practices`. Their knowledge now ships with the packages themselves (Next.js bundles its docs in `node_modules/next/dist/docs/`) or comes from the maintained upstream skills linked in Based On of [1.0.18](https://github.com/laguagu/claude-code-nextjs-skills/tree/9912f0c#-based-on).

## 📚 See Also

[agents-best-practices](https://github.com/laguagu/agents-best-practices) — skill
auditing, creation and discovery across agent tools.

## 📄 License

MIT for original repository content. Bundled skills retain their upstream
licenses and attribution; see [Based On](#-based-on).
