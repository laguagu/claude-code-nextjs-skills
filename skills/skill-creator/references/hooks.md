# Hooks Reference

Hooks execute shell commands at specific points in Claude's lifecycle.

## Hook Types

### PreToolUse
Executes BEFORE a tool runs. Can allow, deny, or modify input.

**Use cases:**
- Validate tool parameters
- Transform inputs
- Gate permissions

### PostToolUse
Executes AFTER a tool completes successfully.

**Use cases:**
- Run formatters (prettier, black)
- Validate output
- Log operations

### Stop
Executes when Claude finishes a turn.

**Use cases:**
- Cleanup operations
- Autonomous loops (Ralph pattern)
- Session logging

## Configuration (settings.json)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/validate.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/on-stop.sh"
          }
        ]
      }
    ]
  }
}
```

## Matcher Patterns

- **Exact:** `"Write"` - matches Write tool only
- **Multiple:** `"Write|Edit|MultiEdit"` - matches any listed
- **Wildcard:** `"*"` - matches all tools
- **Bash patterns:** `"Bash(npm *)"` - matches bash commands starting with npm

## Hook Script Format

Scripts receive JSON on stdin and output JSON on stdout.

### PreToolUse Script

**Input (stdin):**
```json
{
  "tool": "Write",
  "input": {
    "file_path": "/path/to/file.js",
    "content": "..."
  }
}
```

**Output (stdout):**
```json
{
  "permissionDecision": "allow",
  "updatedInput": { ... }
}
```

**permissionDecision values:**
- `"allow"` - proceed with tool
- `"deny"` - block tool execution
- `"ask"` - prompt user for permission

### PostToolUse Script

**Input (stdin):**
```json
{
  "tool": "Write",
  "input": { ... },
  "output": { ... }
}
```

**Output (stdout):**
```json
{
  "continue": true,
  "decision": "allow"
}
```

## Example Scripts

### Auto-format on write (PostToolUse)
```bash
#!/bin/bash
# format-on-write.sh
input=$(cat)
file=$(echo "$input" | jq -r '.input.file_path')

if [[ "$file" == *.js ]] || [[ "$file" == *.ts ]]; then
    npx prettier --write "$file" 2>/dev/null
fi

echo '{"continue": true}'
```

### Validate file paths (PreToolUse)
```bash
#!/bin/bash
# validate-path.sh
input=$(cat)
path=$(echo "$input" | jq -r '.input.file_path')

# Block writes to sensitive directories
if [[ "$path" == /etc/* ]] || [[ "$path" == /usr/* ]]; then
    echo '{"permissionDecision": "deny"}'
    exit 0
fi

echo '{"permissionDecision": "allow"}'
```

## Hooks in Skill Frontmatter

Skills can define their own hooks:

```yaml
---
name: my-skill
description: ...
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "./scripts/format.sh"
---
```

## once: true Option

Run hook only once per session:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./setup.sh",
            "once": true
          }
        ]
      }
    ]
  }
}
```
