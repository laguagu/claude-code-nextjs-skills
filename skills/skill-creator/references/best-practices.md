# Skill Authoring Best Practices

Comprehensive reference synthesized from:
- [agentskills.io/skill-creation/best-practices](https://agentskills.io/skill-creation/best-practices)
- [Anthropic platform docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [agentskills.io/specification](https://agentskills.io/specification)

Read this file when writing or reviewing a skill's content quality.

## Contents
- Frontmatter rules
- Description writing guide
- Progressive disclosure
- Content guidelines
- Writing patterns
- Script design
- Anti-patterns to avoid
- Pre-publish checklist

## Frontmatter rules

### `name` field (required)
- 1–64 characters, lowercase `a-z`, digits `0-9`, hyphens `-` only
- No leading/trailing/consecutive hyphens
- Must match the parent directory name
- Prefer gerund form: `processing-pdfs`, `analyzing-data`, `managing-databases`

### `description` field (required)
- 1–1024 characters, non-empty
- **Third person only**: "Processes files" not "I process files" or "You can use this to..."
- Include BOTH what the skill does AND when to use it
- Be **pushy** — agents under-trigger, so list contexts explicitly
- Include keywords users might say even without naming the skill

Good example:
```yaml
description: >
  Analyzes CSV and tabular data — summary statistics, derived columns,
  charts, data cleaning. Use when the user has a CSV, TSV, or Excel file
  and wants to explore, transform, or visualize data, even if they don't
  explicitly mention "CSV" or "analysis."
```

Bad examples:
```yaml
description: Helps with data files.
description: I can help you process Excel files.
```

### Optional fields
- `license` — License name or reference to LICENSE file
- `compatibility` — 1–500 chars, environment requirements
- `metadata` — Key-value map (string → string) for author, version, etc.
- `allowed-tools` — Space-delimited pre-approved tools (experimental)

## Description writing guide

### What makes a description trigger reliably

1. **Use imperative framing**: "Use this skill when..." tells the agent when to act
2. **Focus on user intent**: What is the user trying to achieve, not implementation details
3. **Be pushy**: Explicitly list contexts including non-obvious ones
4. **Include near-miss disambiguation**: Help agents distinguish this skill from adjacent ones
5. **Keep under 1024 chars** — the spec enforces this limit

### Testing descriptions

Create 20 eval queries (8-10 should-trigger, 8-10 should-not-trigger):
- Vary phrasing: formal, casual, typos, abbreviations
- Vary explicitness: direct mentions vs. implicit needs
- Should-not-trigger: focus on **near-misses**, not obviously irrelevant queries
- Use `run_loop.py` for automated optimization (see main SKILL.md)

## Progressive disclosure

### Three-level loading system

| Level | What loads | When | Budget |
|-------|-----------|------|--------|
| L1 Metadata | name + description | Always (all skills) | ~100 tokens |
| L2 Instructions | Full SKILL.md body | When triggered | <5000 tokens / <500 lines |
| L3 Resources | references/, scripts/, assets/ | On demand | Unlimited |

### Rules
- SKILL.md body under **500 lines** — split into references when approaching
- References **one level deep** from SKILL.md (no A → B → C chains)
- **Table of contents** in reference files >100 lines
- Tell the agent **when** to load each reference: "Read X if condition Y"
- Name files descriptively: `form_validation_rules.md` not `doc2.md`

### Organizational patterns

**Domain-based** (when skill covers multiple domains):
```
bigquery-skill/
├── SKILL.md (overview + navigation)
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

**Complexity-based** (basic in SKILL.md, advanced in references):
```markdown
## Basic usage
[inline instructions]

## Advanced features
See [references/advanced.md](references/advanced.md)
```

## Content guidelines

### Add only what the agent lacks

Challenge each piece of content:
- "Would the agent get this wrong without this instruction?"
- "Can it figure this out by reading the code?"
- "Does this paragraph justify its token cost?"

Don't explain what PDFs are, how HTTP works, or general programming concepts.

### Match specificity to fragility

| Freedom level | When to use | Example |
|--------------|-------------|---------|
| **High** (general guidelines) | Multiple valid approaches, context-dependent | Code review checklist |
| **Medium** (pseudocode/configurable) | Preferred pattern with acceptable variation | Report generator with options |
| **Low** (exact scripts, no params) | Fragile operations, consistency critical | Database migration commands |

### Explain the why

Reasoning-based instructions outperform rigid directives:
- Good: "Filter test accounts because production reports include them otherwise, which inflates metrics"
- Bad: "ALWAYS filter test accounts. NEVER skip this step."

### Use imperative form

Write instructions as commands: "Run the validator", "Check the output", "Read the schema".

## Writing patterns

### Gotchas section (highest value)
Environment-specific facts that defy reasonable assumptions:
```markdown
## Gotchas
- users table uses soft deletes — include WHERE deleted_at IS NULL
- User ID: user_id (DB), uid (auth), accountId (billing) — same value
- /health returns 200 even if DB is down — use /ready for full check
```

### Template pattern
```markdown
## Report structure
Use this template, adapting as needed:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

### Examples pattern (input/output pairs)
```markdown
**Example 1:**
Input: Added user auth with JWT
Output: feat(auth): implement JWT-based authentication
```

### Workflow with checklist
```markdown
- [ ] Step 1: Analyze (run scripts/analyze.py)
- [ ] Step 2: Configure (edit config.json)
- [ ] Step 3: Validate (run scripts/validate.py)
- [ ] Step 4: Execute (run scripts/process.py)
```

### Validation loops
```markdown
1. Make edits
2. Validate: python scripts/validate.py output/
3. If fails → fix → validate again
4. Only proceed when validation passes
```

### Plan-validate-execute
For batch/destructive operations:
1. Create plan file (structured JSON)
2. Validate plan against source of truth
3. Fix if validation fails
4. Execute only after validation passes

### Conditional workflows
```markdown
**New content?** → Follow "Creation workflow"
**Editing existing?** → Follow "Editing workflow"
```

## Script design for agents

### When to bundle scripts
- Agent independently reinvents the same logic across test runs
- Operation is deterministic and exact same every time
- Complex commands that are hard to get right on first try

### Design rules
- **No interactive prompts** — agents run in non-interactive shells
- **Include `--help`** — how agents learn the interface
- **Helpful errors**: "Field 'x' not found. Available: a, b, c"
- **Structured output** — JSON/CSV to stdout, diagnostics to stderr
- **Idempotent** — "create if not exists" not "create and fail on duplicate"
- **Pin versions** — `uvx ruff@0.8.0`, `npx eslint@9.0.0`

### Self-contained Python scripts (PEP 723)
```python
# /// script
# dependencies = ["beautifulsoup4>=4.12,<5"]
# ///
```
Run with: `uv run scripts/extract.py`

## Anti-patterns to avoid

| Anti-pattern | Why it's bad | Fix |
|-------------|-------------|-----|
| Vague description | Skill won't trigger on relevant prompts | Be specific, include trigger contexts |
| SKILL.md >500 lines | Wastes context, agent struggles to extract relevant info | Split into references |
| Deeply nested refs (A→B→C) | Agent partially reads, misses info | One level deep only |
| Windows paths (`\`) | Breaks on Unix systems | Always use `/` |
| Time-sensitive info | Becomes stale | Use "old patterns" section |
| Inconsistent terminology | Confuses agent | Pick one term per concept |
| Too many options | Agent can't choose | Provide default + escape hatch |
| Magic constants | Nobody knows why | Document every value |
| Missing validation loops | Errors caught too late | Validate after each step |
| Over-explaining basics | Wastes tokens | Trust the agent's knowledge |
| First-person descriptions | Discovery problems | Always third person |
| Overly rigid MUSTs | Less effective | Explain the reasoning instead |
| Prescribing technique to a trained agent | Restates the model's training, adds noise, and the model may follow it literally even when wrong | Specify *intent* (scope, output, success criteria) — let the model choose technique |

## Pre-publish checklist

### Core quality
- [ ] `name` matches directory, lowercase+hyphens, 1–64 chars
- [ ] `description`: specific, third person, includes triggers, <1024 chars
- [ ] SKILL.md body under 500 lines
- [ ] Additional detail in `references/` files
- [ ] No time-sensitive information
- [ ] Consistent terminology
- [ ] Concrete examples (not abstract)
- [ ] File references one level deep
- [ ] Progressive disclosure used appropriately

### Scripts (if applicable)
- [ ] Handle errors explicitly with helpful messages
- [ ] No magic constants
- [ ] Dependencies listed and version-pinned
- [ ] Forward slashes in all paths
- [ ] Validation steps for critical operations
- [ ] `--help` output for each script

### Testing
- [ ] 2–3 realistic test prompts
- [ ] Tested with real usage scenarios
- [ ] Description triggers correctly (not too narrow/broad)
