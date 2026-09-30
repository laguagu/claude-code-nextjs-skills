---
title: Agents in AI SDK 7
description: Build ToolLoopAgent and WorkflowAgent agents with AI SDK 7.
---

# Agent execution contracts

Choose `ToolLoopAgent` for an in-memory request lifecycle, `WorkflowAgent`
from `@ai-sdk/workflow` for durable workflow-backed execution, and
`HarnessAgent` from `@ai-sdk/harness/agent` for a runtime such as Claude Code
or Codex.

ToolLoopAgent accepts generation/streaming calls and infers UI message types
with `InferAgentUIMessage`. Request state belongs in per-call options or
`prepareCall`, not a mutable singleton shared across tenants.

`runtimeContext` is shared loop state; `toolsContext` is validated per-tool
state through `contextSchema`. Put information the model needs in instructions
or messages, not only context.

WorkflowAgent has `stream()` only (no `generate()`), runs inside a
`'use workflow'` function, writes `ModelCallStreamPart`s to
`getWritable()` from `workflow`, and has no default step limit. Convert at the
route with `run.readable.pipeThrough(createModelCallToUIChunkTransform())`.
Durable tool work uses `'use step'`; context must be serializable. Approval
stays tool-level `needsApproval` (ToolLoopAgent uses `toolApproval`); signed
approvals take `experimental_toolApprovalSecret: { environmentVariable }` so
raw keys are not serialized into durable steps. Install `@ai-sdk/workflow`
with `workflow@beta` (Workflow 5 peer), not whatever `workflow` is installed.

Read installed workflow types before adapting core agent helpers. Start from
`docs/03-agents/` (`02-building-agents`, `07-workflow-agent`) or the
[agent docs](https://ai-sdk.dev/docs/agents/building-agents);
for runtime-owned history see [harnesses.md](harnesses.md).
