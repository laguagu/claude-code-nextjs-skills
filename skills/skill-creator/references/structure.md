# Skill Structure

## Directory Layout

```
skill-name/
├── SKILL.md              # Required - main instructions
├── references/           # Optional - additional docs (loaded on-demand)
│   ├── api.md
│   └── guide.md
├── scripts/              # Optional - executable code (NOT loaded into context)
│   └── helper.py
└── assets/               # Optional - templates, images (used in output)
    └── template.txt
```

## SKILL.md (Required)

Every skill needs a `SKILL.md` file with:

1. **YAML Frontmatter** (between `---` markers)
2. **Markdown Body** (instructions)

```yaml
---
name: skill-name
description: What it does and when to use it.
---

# Skill Name

## Instructions
Step-by-step guidance for Claude.

## Examples
Concrete examples of usage.
```

## Bundled Resources

### references/ - Documentation
- Loaded into context when Claude reads them
- Use for: detailed guides, API docs, schemas
- Keep referenced from SKILL.md: "See [references/api.md](references/api.md)"

### scripts/ - Executable Code
- NOT loaded into context (only output is)
- Use for: deterministic operations, validation, formatting
- More reliable than Claude-generated code
- Saves tokens and time

**Example script usage in SKILL.md:**
```markdown
Run validation:
\`\`\`bash
python scripts/validate.py input.json
\`\`\`
```

### assets/ - Output Resources
- NOT loaded into context
- Use for: templates, images, boilerplate code
- Claude copies/uses these in output

## Progressive Disclosure

Skills use progressive disclosure to save context:

| Level | When Loaded | Token Cost |
|-------|-------------|------------|
| Metadata (name, description) | Always at startup | ~100 tokens |
| SKILL.md body | When skill triggered | <5k tokens |
| references/ files | When explicitly read | As needed |
| scripts/ | Never (only output) | 0 tokens |

**Best practice:** Keep SKILL.md under 500 lines. Move detailed content to references/.

## File Paths

Always use forward slashes, even on Windows:
- Good: `references/guide.md`
- Bad: `references\guide.md`
