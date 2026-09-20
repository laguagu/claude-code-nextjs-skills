# Cross-client skill discovery

The [Agent Skills specification](https://agentskills.io/specification) defines
skill contents, not a universal installation directory. Verify discovery in the
target client's current documentation.

| Client | Project skills | User skills |
|---|---|---|
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | `~/.claude/skills/` |
| [Codex](https://developers.openai.com/codex/skills) | `.agents/skills/` | `~/.agents/skills/` |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` or `.agents/skills/` | `~/.gemini/skills/` or `~/.agents/skills/` |

For other clients, consult their own docs instead of assuming these paths work.
Plugin installation is separate: a plugin can expose its `skills/` directory
through the client's plugin loader even though a bare repository `skills/`
directory is not a standard auto-discovery path.

To share a collection kept in `~/.agents/skills/` with Claude Code, use supported
symlinks/junctions from its skill directory or distribute a plugin. Preserve any
existing destination content and verify the resulting skill list in each client.

## Portability checks

- Keep shared frontmatter within the specification. Claude extensions such as
  `argument-hint` may be useful for a Claude-only package but are rejected by
  strict spec validators; other clients' behavior varies.
- Do not rely on Claude's shell interpolation or `$ARGUMENTS` substitution in
  a shared skill. Describe the command/action explicitly for other hosts.
- Use relative forward-slash paths and state runtime/tool prerequisites.
- Resolve MCP tool names from the current host: namespace conventions differ.
- Use a model supported by the test runner's provider. `claude -p` cannot run a
  Codex/OpenAI model just because that model authored the skill.
- Validate with `uvx --from skills-ref agentskills validate <skill-folder>`, then
  test discovery and a representative request in each supported client.
