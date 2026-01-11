# Sub-Agents Reference

Sub-agents are specialized agents that handle specific types of tasks.

## Built-in Sub-Agent Types

### Explore
Fast, lightweight agent for code search and analysis.

**Capabilities:**
- Read-only operations only
- File discovery and search
- Codebase exploration
- Quick pattern matching

**Tools available:** ls, git status, git log, git diff, find, cat, head, tail, Glob, Grep, Read

**Use when:**
- Searching for files or patterns
- Understanding codebase structure
- Read-only analysis

### Plan
Research and planning agent.

**Capabilities:**
- Gather codebase information
- Design implementation approaches
- Cannot spawn other sub-agents

**Use when:**
- Planning complex implementations
- Researching before coding

### General-Purpose
Full-capability agent for complex tasks.

**Capabilities:**
- All tools available
- Can modify files
- Multi-step operations
- Complex reasoning

**Use when:**
- Tasks requiring file modifications
- Complex multi-step operations
- Tasks needing multiple strategies

## Custom Sub-Agents

Create custom agents as Markdown files.

### Location
- **User-level:** `~/.claude/agents/my-agent.md`
- **Project-level:** `.claude/agents/my-agent.md`

### Format

```yaml
---
name: my-custom-agent
description: When this agent should be invoked
skills: skill1, skill2
tools: Read, Write, Bash
model: sonnet
permissionMode: default
---

# My Custom Agent

Instructions for the agent to follow.

## Workflow
1. Step one
2. Step two
3. Step three
```

### Frontmatter Fields

| Field | Description |
|-------|-------------|
| `name` | Agent identifier |
| `description` | When to invoke this agent |
| `skills` | Comma-separated skills to load |
| `tools` | Restrict available tools (omit to inherit all) |
| `model` | Model to use (sonnet, opus, haiku) |
| `permissionMode` | Permission handling mode |

## context: fork

Run a skill in an isolated sub-agent context.

```yaml
---
name: complex-analyzer
description: Deep code analysis
context: fork
---
```

**Benefits:**
- Separate conversation history
- Doesn't clutter main context
- Isolated state
- Better for intensive operations

## agent Field in Skills

Specify which agent type runs a skill:

```yaml
---
name: quick-search
description: Fast file search
agent: explore
---
```

## Skills in Custom Agents

Only custom agents with explicit `skills` field can use Skills:

```yaml
---
name: data-processor
description: Process data files
skills: csv-analyzer, chart-maker
---
```

**Note:** Built-in agents (Explore, Plan) do NOT have access to your custom skills.

## Disabling Agents

Disable specific agents in settings.json:

```json
{
  "permissions": {
    "deny": ["Task(AgentName)"]
  }
}
```

Or via CLI:
```bash
claude --disallowedTools "Task(Explore)"
```

## Thoroughness Levels

When invoking Explore agent, specify thoroughness:

- **quick** - Fast, targeted searches
- **medium** - Balanced speed/depth
- **very thorough** - Comprehensive analysis

## Nesting Rules

- Sub-agents cannot spawn other sub-agents
- Prevents infinite recursion
- Plan agent has this restriction built-in
