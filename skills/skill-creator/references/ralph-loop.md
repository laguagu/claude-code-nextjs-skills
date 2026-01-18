# Ralph Loop - Autonomous Iteration

Ralph Loop implements the Ralph Wiggum technique - an iterative development methodology based on continuous AI loops, pioneered by Geoffrey Huntley.

## Official Plugin

Install the official ralph-loop plugin:

```bash
claude plugin install ralph-loop@claude-plugins-official
```

Usage:

```bash
/ralph-loop:ralph-loop "Build a REST API" --max-iterations 50 --completion-promise "DONE"
/ralph-loop:cancel-ralph  # Cancel active loop
/ralph-loop:help          # Show help
```

## Core Concept

```bash
while :; do
  cat PROMPT.md | claude-code --continue
done
```

The same prompt is fed to Claude repeatedly. The "self-referential" aspect comes from Claude seeing its own previous work in the files and git history, not from feeding output back as input.

Each Iteration:

1. Claude receives the SAME prompt
2. Works on the task, modifying files
3. Tries to exit
4. Stop hook intercepts and feeds the same prompt again
5. Claude sees its previous work in the files
6. Iteratively improves until completion

The technique is described as "deterministically bad in an undeterministic world" - failures are predictable, enabling systematic improvement through prompt tuning.

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

To signal completion, output a `<promise>` tag:

```xml
<promise>TASK COMPLETE</promise>
```

The stop hook looks for this specific tag. Without it (or `--max-iterations`), Ralph runs infinitely.

## Self-Reference Mechanism

The "loop" doesn't mean Claude talks to itself. It means:

- Same prompt repeated
- Claude's work persists in files
- Each iteration sees previous attempts
- Builds incrementally toward goal

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

## Windows Troubleshooting

The official plugin uses `.sh` (Bash) scripts which don't work natively on Windows. If you get an error like:

```
Error: Bash command failed for pattern "```!
"/usr/bin/bash: command not found
```

**Fix:** Convert the plugin scripts to PowerShell:

1. **Create PowerShell versions** of the scripts in the plugin cache:
   - `C:\Users\<USER>\.claude\plugins\cache\claude-plugins-official\ralph-loop\<hash>\scripts\setup-ralph-loop.ps1`
   - `C:\Users\<USER>\.claude\plugins\cache\claude-plugins-official\ralph-loop\<hash>\hooks\stop-hook.ps1`

2. **Update hooks.json** to use PowerShell:
   ```json
   {
     "hooks": {
       "Stop": [{
         "hooks": [{
           "type": "command",
           "command": "powershell -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.ps1\""
         }]
       }]
     }
   }
   ```

3. **Update ralph-loop.md** command (use `-Command` instead of `-File` for proper argument passing):
   ```markdown
   ```!
   powershell -ExecutionPolicy Bypass -Command "& '${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-loop.ps1' $ARGUMENTS"
   ```
   ```

4. **Add argument parsing to setup-ralph-loop.ps1** (handles single-string arguments):

   ```powershell
   # Add after param() block:
   if ($Arguments.Count -eq 1 -and $Arguments[0] -match '\s') {
       $RawInput = $Arguments[0]
       $Parsed = [System.Management.Automation.PSParser]::Tokenize($RawInput, [ref]$null) |
           Where-Object { $_.Type -eq 'String' -or $_.Type -eq 'CommandArgument' } |
           ForEach-Object { $_.Content }
       if ($Parsed -and $Parsed.Count -gt 0) {
           $Arguments = $Parsed
       } else {
           $Arguments = $RawInput -split '\s+'
       }
   }
   ```

5. **Restart Claude Code** to apply changes.

**Common Windows errors:**

- `"Error: No prompt provided"` → Arguments not passing correctly, use `-Command` syntax above
- `"Bash command permission check failed"` → Claude Code blocking multi-part commands

The PowerShell scripts implement the same logic as Bash versions but use native Windows commands.

## Learn More

- [Original technique](https://ghuntley.com/ralph/)
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator)
- [Awesome Claude - Ralph Wiggum](https://awesomeclaude.ai/ralph-wiggum)
