---
name: skill-creator
description: Creates Claude Code skills, hooks, MCP configs, and custom agents. Use when user wants to create a skill, needs help with SKILL.md, asks about hooks, MCP servers, sub-agents, or autonomous workflows like Ralph loop.
---

# Skill Creator

Create high-quality Claude Code skills, hooks, MCP configurations, and custom agents.

## Quick Start: Create a Skill

1. Create directory: `~/.claude/skills/your-skill-name/`
2. Create `SKILL.md` with frontmatter and instructions
3. Skill is immediately available via `/your-skill-name`

**Minimal SKILL.md:**
```yaml
---
name: your-skill-name
description: What it does. Use when [specific triggers].
---

# Your Skill Name

Instructions for Claude to follow.
```

## Detailed References

- **Structure**: See [references/structure.md](references/structure.md) for directory layout and bundled resources
- **Frontmatter**: See [references/frontmatter.md](references/frontmatter.md) for all YAML fields
- **Best Practices**: See [references/best-practices.md](references/best-practices.md) for writing effective skills
- **Hooks**: See [references/hooks.md](references/hooks.md) for PreToolUse, PostToolUse, Stop hooks
- **MCP**: See [references/mcp.md](references/mcp.md) for MCP server configuration
- **Sub-Agents**: See [references/sub-agents.md](references/sub-agents.md) for custom agents
- **Ralph Loop**: See [references/ralph-loop.md](references/ralph-loop.md) for autonomous iteration
- **Examples**: See [references/examples.md](references/examples.md) for complete examples

## Scripts

```bash
# Initialize new skill
python scripts/init_skill.py my-skill --path ~/.claude/skills/

# Validate SKILL.md
python scripts/quick_validate.py path/to/skill

# Package for distribution
python scripts/package_skill.py path/to/skill
```

## Quality Checklist

Before deploying a skill, verify:

- [ ] `name`: lowercase, hyphens, max 64 chars
- [ ] `description`: includes WHAT it does and WHEN to use it
- [ ] SKILL.md body under 500 lines
- [ ] Large content split into references/
- [ ] No time-sensitive information
- [ ] Tested with real usage scenarios

## Common Patterns

**Skill with references:**
```
skill-name/
├── SKILL.md
└── references/
    ├── api.md
    └── examples.md
```

**Skill with scripts:**
```
skill-name/
├── SKILL.md
└── scripts/
    └── helper.py
```

**Skill with hooks:**
Add to `settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{"type": "command", "command": "./format.sh"}]
    }]
  }
}
```
