# Example: global agent instructions

User-wide working rules for a coding agent, written for long autonomous runs. The
wording follows Anthropic's
[Getting the most out of Opus 5.5](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)
guide: say which stops you want and lead a report with what needs the reader. The
guide's "treat that answer as done" lines are left out on purpose: Anthropic's
[Opus 5.5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5#thinking-instructions-in-chat-system-prompts)
and [Fable 5.2](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2#review-instructions-written-for-earlier-models)
prompting guides keep them for chat, because in agentic work they make the model less
likely to point out its own earlier mistakes.

Copy the block below into `~/.claude/CLAUDE.md` (Claude Code) or `~/.codex/AGENTS.md`
(Codex), then delete what does not match how you work. Keep project facts such as
commands, architecture and conventions in each repository's own `AGENTS.md`.

```markdown
Use Bun for JavaScript packages and scripts in new projects (`bun add`, `bunx --bun`).
In an existing project, follow its lockfile and `packageManager` field instead.

## Working style

When a step doesn't need my input, keep going. Put status notes in the same message as
your next action; keep a session checklist for long tasks. Stop and ask only when you
can't continue without me, or before anything destructive: deleting data, force-pushing,
or changing anything outside the repos the task is about.

Decide reversible technical and product choices yourself and report them as decided,
with the reason. Bring me only decisions that need my account, money, publication or
legal judgement, each with a recommendation. A status report leads with what needs
me, then what was decided and what I can try.

## Background agents

- A usage limit or a restart can cut background agents mid-work: workers commit their
  own verified paths on the working branch as they go and keep a short progress note
  beside their output; the lead reviews afterwards.
- Before a large fan-out, check how much of the usage window is left. When it is nearly
  spent, commit first and write an "In flight" list into the repo's `HANDOFF.md`
  instead of launching more workers.
- Another agent session may share this checkout and its index: commit by path
  (`git commit -- <paths>`). A plain `git commit` also takes what the other session
  has staged.
- Workers write their report to a named file and return the path and a few lines.
```

## Why each part is there

| Rule | What it prevents |
| --- | --- |
| Keep going; stop only when blocked or before destructive actions | A long run that pauses after every step to ask for permission it did not need |
| Decide reversible choices and report them | Questions about details you would have accepted either way |
| A report leads with what needs you, then decisions and what to try | Having to read a full summary to find the one thing that needs you |
| Workers commit as they go | Losing finished work when a limit or restart ends the session |
| Commit by path | One session's commit taking another session's staged, half-finished files |
