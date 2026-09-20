# Next.js + AI Skills

24 skills for Next.js, AI SDK, shadcn/ui, PostgreSQL search and browser verification,
plus two Claude Code agents. Browse [skills](skills/) and [agents](agents/).

## Install

In Claude Code:

```text
/plugin marketplace add laguagu/claude-code-nextjs-skills
/plugin install claude-code-nextjs-skills@laguagu
```

Invoke, for example, `/claude-code-nextjs-skills:ai-app` or
`/claude-code-nextjs-skills:go`. Skills can also activate from relevant requests.
Update with `/plugin marketplace update laguagu`, then
`/plugin update claude-code-nextjs-skills@laguagu`.

For individual skills, copy a skill folder into your client's supported skills
directory: `.claude/skills/` for Claude Code or `.agents/skills/` for Codex.
Copy any referenced sibling skills too.
The corresponding user-wide directories are `~/.claude/skills/` and `~/.agents/skills/`.

The root [plugin.json](plugin.json) also packages the collection in
[Agent Plugins format](https://agent-plugins.org/). Installation and feature
support depend on the client; the package format alone does not guarantee support.

## Included

- **Apps:** ai-app, nextjs-shadcn, nextjs-chatbot
- **UI:** ai-elements, shadcn, icons, frontend-design, web-design-guidelines
- **Next.js / React:** next-best-practices, cache-components, nextjs-seo,
  react-best-practices, vercel-react-view-transitions
- **AI SDKs:** ai-sdk (version discovery), ai-sdk-6, ai-sdk-7, openai-agents-sdk (Python)
- **PostgreSQL:** postgres-semantic-search, supabase-postgres-best-practices
- **Tools:** chrome-devtools, go, handoff, hetzner-cloud, skill-creator
- **Agents:** code-simplifier, e2e-tester

[mcp.json](mcp.json) configures Next.js DevTools and the AI Elements registry.
The Claude plugin manifest points to this same file. Chrome DevTools MCP is
optional; setup is in its [skill](skills/chrome-devtools/SKILL.md).

## Maintenance and license

Edit shared skills in `~/.agents/skills/`; this maintainer checkout links `skills/*`
there. Git publishes regular files, so clones are self-contained. Validate with
`uvx --from skills-ref agentskills validate <skill-folder>` and
`claude plugin validate .` before publishing.

MIT for original repository content. Retain each bundled skill's license and
attribution when updating it. Upstream sources include [Vercel AI](https://github.com/vercel/ai),
[Next.js](https://github.com/vercel/next.js), [Vercel agent skills](https://github.com/vercel-labs/agent-skills),
[Vercel plugin](https://github.com/vercel-labs/vercel-plugin),
[Anthropic skills](https://github.com/anthropics/skills),
[Supabase agent skills](https://github.com/supabase/agent-skills),
[shadcn/ui](https://github.com/shadcn-ui/ui), and
[Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills).
