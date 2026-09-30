---
title: Type-Safe useChat with Agents
description: Build end-to-end type-safe agents by inferring UIMessage types from your agent definition.
---

# Typed agent UI

Infer the UI message type from the server agent with
`InferAgentUIMessage<typeof agent>` and pass it to `useChat`. WorkflowAgent
uses `InferWorkflowAgentUIMessage` from `@ai-sdk/workflow`; verify the
installed package signature.

Export types alongside the agent/tools and import them with `import type` in
client modules. A type-only dependency avoids bundling provider clients,
credentials or tool implementations into the browser.

Typed tool parts use the key in the agent's `tools` object:
`tool-{toolName}`. Narrow type and state before reading partial input or completed
output. For a dedicated component, `UIToolInvocation<typeof tool>` can express
the invocation contract without copying its schema.

Inference does not validate untrusted request JSON or restored history. Validate
those at the server boundary with
`validateUIMessages({ messages, tools, metadataSchema, dataSchemas })`. Supply
the relevant schemas: omitting them skips validation of that data.

See [agent UI integration](https://ai-sdk.dev/docs/agents/building-agents)
and the installed `useChat` types for examples and generic parameters.
