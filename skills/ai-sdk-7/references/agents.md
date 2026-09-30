---
title: Agents in AI SDK 7
description: Build ToolLoopAgent and WorkflowAgent agents with AI SDK 7.
---

# Agent execution contracts

Choose `ToolLoopAgent` for an in-memory request lifecycle, `WorkflowAgent`
from `@ai-sdk/workflow` for durable workflow-backed execution, and
`HarnessAgent` for a runtime such as Claude Code or Codex. Text functions
default to one step, `ToolLoopAgent` to 20; `WorkflowAgent` has no default
step-count limit. Set `stopWhen` for the task budget.

ToolLoopAgent accepts generation/streaming calls and infers UI message types
with `InferAgentUIMessage`. Request state belongs in per-call options or
`prepareCall`, not a mutable singleton shared across tenants.

`runtimeContext` is shared loop state; `toolsContext` is validated per-tool
state through `contextSchema`. Put information the model needs in instructions
or messages, not only context.

WorkflowAgent is stream-first (`generate()` throws), writes
`ModelCallStreamPart` chunks to a workflow writable and converts them at the UI
boundary with `createModelCallToUIChunkTransform()`. Durable tool work uses
`'use step'`; context must be serializable. Its approval API remains tool-level
`needsApproval`, while ToolLoopAgent uses `toolApproval`. UI types come from
`InferWorkflowAgentUIMessage`. It replaces Workflow DevKit's `DurableAgent`.
The package peer-requires `workflow` 5 (`^5.0.0-beta`; the bundled guide installs
`workflow@beta`), not 4.x. Signed approvals use
`experimental_toolApprovalSecret: { environmentVariable }` so raw keys are not
serialized into durable steps.

Read installed workflow types before adapting core agent helpers. Start from
[agent docs](https://ai-sdk.dev/docs/agents/building-agents) and
[WorkflowAgent docs](https://ai-sdk.dev/docs/agents/workflow-agent);
for runtime-owned history see [harnesses.md](harnesses.md).
