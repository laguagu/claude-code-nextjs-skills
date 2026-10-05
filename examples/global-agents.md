# Example: global agent instructions

User-wide working rules for a coding agent, written for long autonomous runs. The
wording follows Anthropic's
[Getting the most out of Opus 5.5](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)
guide: say which stops you want, treat answered questions as settled, and lead a report
with what needs the reader.

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

Once you have answered something, treat that answer as done. Focus on what I'm asking
now, and don't go back over an earlier answer unless I ask about it, point out a
problem with it, or you find it was wrong.

Decide reversible technical and product choices yourself and report them as decided,
with the reason. Bring me only decisions that need my account, money, publication or
legal judgement, each with a recommendation. A status report leads with what was
decided and what I can try.

## Background agents

- A usage limit or a restart can cut background agents mid-work: workers commit their
  own verified paths on the working branch as they go and keep a short progress note
  beside their output; the lead reviews afterwards.
- Before a large fan-out, check how much of the usage window is left. When it is nearly
  spent, commit first and write an "In flight" list into the repo's `HANDOFF.md`
  instead of launching more workers.
- Another agent session may share this checkout: stage by path, never `git add -A` or
  `git add .`.
- Workers write their report to a named file and return the path and a few lines.
```

## Why each part is there

| Rule | What it prevents |
| --- | --- |
| Keep going; stop only when blocked or before destructive actions | A long run that pauses after every step to ask for permission it did not need |
| Treat an answer as done, unless it turns out wrong | Later replies that reopen and re-explain earlier answers |
| Decide reversible choices and report them | Questions about details you would have accepted either way |
| A report leads with what was decided and what to try | Having to read a full summary to find the one thing that needs you |
| Workers commit as they go | Losing finished work when a limit or restart ends the session |
| Stage by path | One session committing another session's half-finished files |
