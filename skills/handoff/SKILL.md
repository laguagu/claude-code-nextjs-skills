---
name: handoff
description: Write or update a HANDOFF.md so a fresh agent can continue this work. Use when the user says "handoff", "compact this", "context is full", or "/clear and continue".
argument-hint: "What will the next session focus on?"
---

Write or update a handoff document so the next agent with fresh context can continue.

## Steps

1. If `HANDOFF.md` exists in the project root, read it first.
2. Do not duplicate content already in PRDs, plans, ADRs, issues, commits, or diffs — reference them by path or URL.
3. Write or update `HANDOFF.md` in the project root with:
   - **Goal** — what we're trying to accomplish
   - **Current Progress** — what's done (link commits/PRs)
   - **What Worked** — approaches that succeeded
   - **What Didn't Work** — dead ends, so they aren't retried
   - **Next Steps** — concrete action items
   - **Suggested skills** — which skills the next session should load, if any
4. If the user passed arguments, tailor the doc to that focus.
5. Tell the user the path so they can start a fresh conversation with it.
