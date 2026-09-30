---
title: Agents in AI SDK 7
description: Build ToolLoopAgent and WorkflowAgent agents with AI SDK 7.
---

# Agent execution contracts

Choose `ToolLoopAgent` for an in-memory request lifecycle, `WorkflowAgent`
from `@ai-sdk/workflow` for durable workflow-backed execution, and
`HarnessAgent` for a runtime such as Claude Code or Codex.

ToolLoopAgent accepts generation/streaming calls and infers UI message types
with `InferAgentUIMessage`. Request state belongs in per-call options or
`prepareCall`, not a mutable singleton shared across tenants.

`runtimeContext` is shared loop state; `toolsContext` is validated per-tool
state through `contextSchema`. Put information the model needs in instructions
or messages, not only context.

WorkflowAgent is stream-first, writes model chunks to a workflow writable and
uses a conversion at the UI boundary. Durable tool work uses `'use step'`;
context must be serializable. Its approval API remains tool-level
`needsApproval`, while ToolLoopAgent uses `toolApproval`. Inference and
callback APIs also differ. Read the workflow package's peer/runtime requirements;
the current guide requires Workflow 5 (beta), rather than any installed
Workflow release. Signed approvals use an environment-variable reference so
raw keys are not serialized into durable steps.

Read installed workflow types before adapting core agent helpers. Start from
[agent docs](https://ai-sdk.dev/docs/agents/building-agents) and
[WorkflowAgent docs](https://ai-sdk.dev/docs/agents/workflow-agent);
for runtime-owned history see [harnesses.md](harnesses.md).
