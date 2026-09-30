# AI SDK 6 agents

Use `ToolLoopAgent` for a reusable in-memory tool loop. It takes
`instructions`, unlike v6 text functions' `system` option. Configure
`stopWhen` with `stepCountIs` for the task's budget.

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

Find details in the installed `docs/agents/` and `ToolLoopAgent` source or the
[official agent guide](https://ai-sdk.dev/docs/agents/building-agents) set to v6.
