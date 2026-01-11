# Complete Skill Examples

## Example 1: Simple Skill (Minimal)

**Location:** `~/.claude/skills/git-commit-helper/SKILL.md`

```yaml
---
name: git-commit-helper
description: Generates descriptive git commit messages. Use when user asks for help writing commits or reviewing staged changes.
---

# Git Commit Helper

Generate commit messages following conventional commits format.

## Format
```
type(scope): description

[optional body]
```

## Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

## Process
1. Run `git diff --staged` to see changes
2. Analyze the changes
3. Generate appropriate commit message
4. Present to user for approval
```

## Example 2: Skill with References

**Structure:**
```
~/.claude/skills/api-builder/
├── SKILL.md
└── references/
    ├── patterns.md
    └── validation.md
```

**SKILL.md:**
```yaml
---
name: api-builder
description: Builds REST APIs with Express/FastAPI. Use when creating APIs, endpoints, or backend services.
---

# API Builder

Build production-ready REST APIs.

## Quick Start

Express (Node.js):
\`\`\`javascript
const express = require('express');
const app = express();
app.use(express.json());
\`\`\`

FastAPI (Python):
\`\`\`python
from fastapi import FastAPI
app = FastAPI()
\`\`\`

## References
- **Design patterns**: See [references/patterns.md](references/patterns.md)
- **Input validation**: See [references/validation.md](references/validation.md)
```

**references/patterns.md:**
```markdown
# API Design Patterns

## Resource Naming
- Use nouns: `/users`, `/posts`
- Use plural: `/users` not `/user`
- Nest for relationships: `/users/:id/posts`

## HTTP Methods
| Method | Action | Example |
|--------|--------|---------|
| GET | Read | GET /users |
| POST | Create | POST /users |
| PUT | Replace | PUT /users/1 |
| PATCH | Update | PATCH /users/1 |
| DELETE | Remove | DELETE /users/1 |

## Response Codes
- 200: Success
- 201: Created
- 400: Bad Request
- 404: Not Found
- 500: Server Error
```

## Example 3: Skill with Scripts

**Structure:**
```
~/.claude/skills/code-formatter/
├── SKILL.md
└── scripts/
    └── format.sh
```

**SKILL.md:**
```yaml
---
name: code-formatter
description: Formats code files. Use when user wants to format, lint, or clean up code.
allowed-tools:
  - Read
  - Write
  - Bash
---

# Code Formatter

Format code files using appropriate tools.

## Usage

Run the formatter:
\`\`\`bash
./scripts/format.sh <file>
\`\`\`

## Supported Languages
- JavaScript/TypeScript: Prettier
- Python: Black
- Go: gofmt
- Rust: rustfmt
```

**scripts/format.sh:**
```bash
#!/bin/bash
file="$1"
ext="${file##*.}"

case "$ext" in
    js|ts|jsx|tsx|json)
        npx prettier --write "$file"
        ;;
    py)
        python -m black "$file"
        ;;
    go)
        gofmt -w "$file"
        ;;
    rs)
        rustfmt "$file"
        ;;
    *)
        echo "Unknown file type: $ext"
        exit 1
        ;;
esac
```

## Example 4: Skill with Hooks

**SKILL.md:**
```yaml
---
name: safe-writer
description: Writes files with automatic backup. Use when making important file changes.
hooks:
  PreToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "./scripts/backup.sh"
---

# Safe Writer

Automatically backs up files before writing.

## How It Works
1. PreToolUse hook triggers before Write
2. Backup script creates copy in .backups/
3. Original write proceeds
4. Backup available if needed

## Restore
\`\`\`bash
cp .backups/filename.bak filename
\`\`\`
```

## Example 5: Forked Context Skill

**SKILL.md:**
```yaml
---
name: deep-analyzer
description: Performs deep code analysis. Use for comprehensive codebase reviews.
context: fork
agent: explore
---

# Deep Code Analyzer

Thorough analysis in isolated context.

## Analysis Steps
1. Map all source files
2. Identify dependencies
3. Find potential issues
4. Generate report

## Output
Creates analysis-report.md with findings.
```

## Example 6: Custom Agent

**Location:** `~/.claude/agents/reviewer.md`

```yaml
---
name: code-reviewer
description: Reviews code changes and provides feedback
skills: git-commit-helper
tools: Read, Grep, Glob, Bash
model: sonnet
---

# Code Reviewer Agent

Review code changes thoroughly.

## Process
1. Get list of changed files
2. Read each file
3. Identify issues:
   - Security concerns
   - Performance problems
   - Code style violations
   - Missing tests
4. Provide actionable feedback

## Output Format
For each issue found:
- File and line number
- Issue description
- Suggested fix
- Severity (high/medium/low)
```

## Example 7: MCP-Integrated Skill

**SKILL.md:**
```yaml
---
name: github-helper
description: Manages GitHub issues and PRs. Use for GitHub operations.
allowed-tools:
  - github
  - Read
  - Write
---

# GitHub Helper

Work with GitHub repositories.

## Create Issue
Use GitHub:create_issue with:
- title: Issue title
- body: Description
- labels: Array of labels

## Create PR
Use GitHub:create_pull_request with:
- title: PR title
- body: Description
- head: Source branch
- base: Target branch

## List Issues
Use GitHub:list_issues to see open issues.
```

## Skill Creation Checklist

When creating a new skill:

1. [ ] Choose descriptive name (lowercase, hyphens)
2. [ ] Write clear description with triggers
3. [ ] Create SKILL.md with basic instructions
4. [ ] Add references/ if content exceeds 500 lines
5. [ ] Add scripts/ for repeatable operations
6. [ ] Test with real scenarios
7. [ ] Iterate based on usage
