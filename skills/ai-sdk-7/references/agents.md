---
title: Agents in AI SDK 7
description: Build ToolLoopAgent and WorkflowAgent agents with AI SDK 7.
---

# Agent execution contracts

Choose `ToolLoopAgent` for an in-memory request lifecycle, `WorkflowAgent`
from `@ai-sdk/workflow` for durable workflow-backed execution, and
`HarnessAgent` for a runtime such as Claude Code or Codex. Text functions
default to one step, `ToolLoopAgent` to 20; `WorkflowAgent.stream()` has no default
step-count limit. Set `stopWhen` for the task budget.

ToolLoopAgent accepts generation/streaming calls and infers UI message types
with `InferAgentUIMessage`. Request state belongs in per-call options or
`prepareCall`, not a mutable singleton shared across tenants.

`runtimeContext` is shared loop state; `toolsContext` is validated per-tool
state through `contextSchema`. Put information the model needs in instructions
or messages, not only context.

WorkflowAgent is stream-first; `generate()` works from `@ai-sdk/workflow` 2.0.59 /
`ai` 7.0.128 with a 20-step default and throws on older versions. Streaming writes
`ModelCallStreamPart` chunks to a workflow writable and converts them at the UI
boundary with `createModelCallToUIChunkTransform()`. Durable tool work uses
`'use step'`; context must be serializable. Its approval API remains tool-level
`needsApproval`, while ToolLoopAgent uses `toolApproval`. UI types come from
`InferWorkflowAgentUIMessage`. It replaces Workflow DevKit's `DurableAgent`.
`@ai-sdk/workflow` 2.0.66 onward peer-requires `workflow ^5.1.0`. Install
`workflow@5`; the `workflow@beta` tag points to an older, incompatible 5.0 beta. Signed approvals use
`experimental_toolApprovalSecret: { environmentVariable }` so raw keys are not
serialized into durable steps.

Read installed workflow types before adapting core agent helpers. Start from
[agent docs](https://ai-sdk.dev/docs/agents/building-agents) and
[WorkflowAgent docs](https://ai-sdk.dev/docs/agents/workflow-agent);
for runtime-owned history see [harnesses.md](harnesses.md).
