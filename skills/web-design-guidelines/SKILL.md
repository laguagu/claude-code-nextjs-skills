---
name: web-design-guidelines
description: Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".
metadata:
  author: vercel
  version: "1.0.0"
---

# Web Interface Guidelines

Review files for compliance with Web Interface Guidelines.

## How It Works

1. Fetch the latest guidelines from the source URL below
2. Read the specified files (or prompt user for files/pattern)
3. Check against all rules in the fetched guidelines

   As of 2026-10-11, `command.md` omits some accessibility checks; for accessibility reviews also check contrast (WCAG 2.2 AA: text 4.5:1, large text and required non-text UI contrast 3:1, with applicable exceptions), status not shown by colour alone, target size (WCAG 2.5.8: >=24 by 24 CSS px with its exceptions; 44px on touch is advisory), mobile input font-size >=16px, and focus moving into and back from modal dialogs per the [APG dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/).

4. Output findings in the terse `file:line` format

## Guidelines Source

Fetch fresh guidelines before each review:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

Retrieve the complete rules with an available web or shell tool. A fetch tool that returns a summary (such as Claude Code's WebFetch) may omit rules; when the shell has network access, `curl` the raw URL instead. Without web access, use the pinned snapshot [references/command.md](references/command.md) and say in the review that it used the snapshot and its date.

## Usage

When a user provides a file or pattern argument:
1. Fetch guidelines from the source URL above
2. Read the specified files
3. Apply all rules from the fetched guidelines
4. Output findings using the format specified in the guidelines

If no files specified, ask the user which files to review.
