# Ralph Loop - Autonomous Iteration

Ralph is a technique for autonomous software development using continuous iteration.

## Official Plugin

Install the official ralph-loop plugin:

```bash
claude plugin install ralph-loop@claude-plugins-official
```

Usage:

```bash
/ralph-loop "Build a REST API" --max-iterations 50 --completion-promise "DONE"
/cancel-ralph  # Cancel active loop
```

## Core Concept

Ralph creates a self-referential loop where Claude:

1. Works on the task
2. Tries to exit
3. Stop hook blocks exit and feeds the prompt back
4. Repeats until completion promise is detected

## When to Use

**Good for:**

- Greenfield projects with clear specs
- Iterative refinement tasks
- Tasks with verifiable completion criteria
- Long-running autonomous work

**Not ideal for:**

- Tasks requiring human judgment
- Ambiguous requirements
- Tasks without clear completion criteria

## Completion Promises

Tell Claude how to signal completion:

```markdown
When the task is complete, output exactly:
<promise>TASK_COMPLETE</promise>

Do not output this until ALL requirements are verified.
```

## Custom Implementation

For custom variations, you can build your own loop using Stop hooks:

### settings.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./ralph-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### ralph-hook.sh

```bash
#!/bin/bash
if grep -q "COMPLETE" /tmp/ralph-status; then
    echo '{"continue": false}'
    exit 0
fi
cat PROMPT.md
echo '{"continue": true}'
```

## Philosophy

Ralph requires "faith and a belief in eventual consistency." Each failure is a tuning opportunity - refine prompts iteratively and treat failures as feedback.
