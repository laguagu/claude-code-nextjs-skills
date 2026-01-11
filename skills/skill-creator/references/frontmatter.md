# YAML Frontmatter Fields

## Required Fields

### name
- **Max length:** 64 characters
- **Allowed:** lowercase letters, numbers, hyphens
- **Forbidden:** XML tags, reserved words ("anthropic", "claude")

```yaml
name: pdf-processor      # Good
name: PDF_Processor      # Bad - uppercase, underscore
name: my-awesome-tool    # Good
```

### description
- **Max length:** 1024 characters
- **Required:** Non-empty
- **Forbidden:** XML tags

**Critical:** Description is the PRIMARY triggering mechanism. Include:
1. WHAT the skill does
2. WHEN to use it (specific triggers)

```yaml
# Good - includes what AND when
description: Extracts text from PDF files. Use when working with PDFs, document extraction, or form processing.

# Bad - only what, no when
description: Processes PDF files.
```

## Optional Fields

### allowed-tools
Restrict which tools Claude can use when skill is active.

```yaml
# Comma-separated string
allowed-tools: Read, Grep, Glob

# YAML list (cleaner)
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
```

### context
Control how skill executes.

```yaml
context: fork    # Run in isolated sub-agent context
```

**context: fork** creates a separate conversation context:
- Prevents cluttering main conversation
- Useful for complex multi-step operations
- Each sub-agent has its own state

### agent
Specify which sub-agent type runs the skill.

```yaml
agent: explore    # Use Explore sub-agent
agent: plan       # Use Plan sub-agent
```

### user-invocable
Control visibility in slash command menu.

```yaml
user-invocable: false    # Hide from menu (still triggers automatically)
user-invocable: true     # Show in menu (default for skills in /skills/)
```

### hooks
Define hooks scoped to this skill's lifecycle.

```yaml
hooks:
  PreToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "./validate.sh"
```

## Complete Example

```yaml
---
name: data-analyzer
description: Analyzes CSV and Excel data files. Use when user mentions data analysis, spreadsheets, CSV files, or asks for charts and statistics.
allowed-tools:
  - Read
  - Write
  - Bash
context: fork
---
```

## Writing Tips

1. **Third person in description** - "Processes files" not "I process files"
2. **Include key terms** - Words users might say to trigger the skill
3. **Be specific** - "Extracts text from PDF" not "Helps with documents"
4. **Avoid vague terms** - "helper", "utils", "tools"
