# AI SDK 6 agents

Use `ToolLoopAgent` for a reusable in-memory tool loop. It takes
`instructions`, unlike v6 text functions' `system` option. `stopWhen` defaults
to `stepCountIs(20)`; set it for the task's budget.

Agent construction describes the reusable policy; per-call options describe
request-specific data. Verify the installed `callOptionsSchema` /
`prepareCall` signatures rather than copying v7 runtime/tool context options.
Do not put credentials or authorization decisions in model-controlled input.

`prepareStep` can adjust active tools, messages and settings. In v6 its
instruction/message overrides are step-local; v7 changes their carry-forward
semantics.

Use `createAgentUIStreamResponse` with `uiMessages` for an SDK UI route.
Validate/authenticate before execution and infer the agent's UI message type.
In-memory execution does not make a run durable across restarts.

Read `docs/03-agents/` (building agents, loop control, call options) and
`src/agent/tool-loop-agent-settings.ts`, or the
[v6 agent guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-agents/02-building-agents.mdx).
