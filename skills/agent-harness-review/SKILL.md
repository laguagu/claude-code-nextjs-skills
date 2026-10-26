---
name: agent-harness-review
description: Reviews an agent harness or agent design against Anthropic's agent and Claude Opus 5.5 guidance, Cognition's context principles and 2026 research on skill routing and skill-induced failures. Covers when subagents or parallel agents pay off, how to brief them, how many skills, plugins, MCP servers and hooks load every session, tool design and proportionate verification. Use when auditing a Claude Code or Codex setup, deciding whether to add subagents or a multi-agent workflow, trimming a skill library, or designing an agent loop in an app. For writing or evaluating a single skill, use skill-creator.
---

# Review an agent harness

The goal is the simplest harness that does the job. Add an agent, subagent, skill,
plugin or hook only where it measurably helps; removing parts and "no change" are
valid outcomes. Match the review to the request: a question about one subagent
needs one answer, a whole-setup audit needs the inventory below.

## Gather evidence before judging

- **What loads every session:** instruction files, the skill list (count, near-duplicate
  names and descriptions), plugins (each can bring skills, hooks, MCP servers and
  agents), MCP servers, custom subagents and hooks that inject context.
- **What is used:** Claude Code transcripts (`~/.claude/projects/**/*.jsonl`) record
  skill calls (`"name":"Skill"`), subagent types (`"subagent_type"`) and MCP calls
  (`mcp__<server>__`); Codex keeps sessions under `~/.codex/sessions`. Low use is a lead,
  not a verdict: a rarely needed domain skill can still be the right one.
- **How the client behaves:** read its current docs for what a setting covers and what
  disabling something removes. In Claude Code, `skillOverrides` does not apply to plugin
  skills, and disabling a plugin also disconnects its MCP servers; a plugin's MCP server
  can be re-added as a user-scoped server.

## What the sources found, and what to check

**Start simple and design the tools** ([Building effective agents](https://www.anthropic.com/research/building-effective-agents)).
Prefer a single call or a fixed workflow when the path is predictable; use an agent
for open-ended work. Keep the design simple, show the agent's planning, and give the
agent-computer interface the care of a prompt: clear tool descriptions with examples
and boundaries between similar tools, formats the model writes easily, and arguments
that make mistakes hard (absolute paths instead of relative ones).

**Delegate breadth, not shared decisions** ([multi-agent research system](https://www.anthropic.com/research/multi-agent-research-system),
[Don't build multi-agents](https://cognition.com/blog/dont-build-multi-agents)).
Agents used about 4× the tokens of chat and multi-agent systems about 15×, so the
task must be worth it. Multi-agent pays off for breadth-first, parallel, read-heavy
work that exceeds one context, and fits poorly where agents need the same context
or depend on each other, which covers most coding. Actions carry implicit decisions:
parallel writers without shared context produce conflicting results, so default to
one writing thread and use subagents to answer questions. Check that delegation
prompts give each subagent an objective, an output format, tools or sources, and
boundaries; that the number of agents scales with the task (one agent with 3–10 tool
calls for a fact, 2–4 for a comparison, more only for wide research; without such a
rule the system spawned 50 subagents for simple queries); and that long results go
to files with a reference back instead of being relayed through the lead.

**Partition large parallel work and check the evidence** ([Prompting Claude Opus 5.5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5),
[Getting the most out of Opus 5.5](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)).
Opus 5.5 runs long audits and migrations with parallel subagents well when each unit
is independent (one service per subagent) and the lead checks each subagent's evidence
before accepting it. This reconciles with the single-writer rule: parallel writers get
separate files or worktrees and no shared decisions. Long runs keep their task list in
a file, state what "done" means and which stops are wanted, and give the lead a time
budget or elapsed time when finishing sooner matters.

**Keep the always-listed skill set small and distinct** ([Lost in Implicit Routing, arXiv 2610.18522](https://arxiv.org/abs/2610.18522)).
With 1,000 irrelevant skills listed, agents loaded the relevant skill far less often
(recall 73.6% → 27.4%) and loaded nothing in 51.6% of tasks (from 9.3%). Hiding only
the irrelevant skills' descriptions largely restored loading; preselecting skills
kept 73.9% recall, and asking the agent to plan its skill use did not match that.
Turn off unused skill bundles, merge near-duplicates and keep descriptions distinct
before adding trigger words to a skill that is not picked.

**Skills can cost more than they help** ([Agent Skills Can Be Harmful, arXiv 2608.11888](https://arxiv.org/abs/2608.11888)).
Across 307 skill-induced failures (125 functional, 182 efficiency), functional
failures came mostly from relevant-looking skills that led the agent to implement
part of the task wrongly or leave it out. The largest efficiency costs were checks
a skill made mandatory regardless of task size (67) and heavy build pipelines (30);
prompt length alone did not explain them. Check that a skill's checks and procedures
scale with the change, and compare a doubtful skill against a no-skill run on the
same task.

**Model settings and instruction wording** (Opus 5.5 guide and blog). Effort is the
main control: start at `medium` and keep `xhigh` and `max` for work where a quality
gain was measured. Remove "think carefully" lines. Name the early stops to avoid and
the stops wanted, keep confirmation for destructive actions, and mark pasted text.

## Report

Lead with what was decided and the evidence for it: measured use, the config or doc
fact, and the source finding. Separate changes made (reversible, with backups) from
decisions that need the owner's account, money or publication. Say what was measured
and what is inferred from a source whose setting differs from the user's.
