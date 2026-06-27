---
title: AI SDK 7 Telemetry
description: OpenTelemetry registration, tracing channel, context filtering, and lifecycle events.
---

# AI SDK 7 Telemetry

AI SDK 7 registers telemetry integrations once at application startup. Do not
wire custom tracing into every model call unless the installed docs require it.

## Register OpenTelemetry

Install `@ai-sdk/otel` when the project uses OpenTelemetry:

```bash
bun add @ai-sdk/otel
```

Register once:

```ts
import { registerTelemetry } from 'ai';
import { OpenTelemetry } from '@ai-sdk/otel';

registerTelemetry(new OpenTelemetry());
```

In Next.js, register from `instrumentation.ts` alongside the app's normal
OpenTelemetry setup.

Telemetry is opt-out after an integration is registered:

```ts
await generateText({
  model: __MODEL__,
  prompt,
  telemetry: { isEnabled: false },
});
```

If no integration is registered, telemetry is disabled globally.

## Per-Call Metadata

Use `telemetry.functionId` and project metadata to identify operations:

```ts
await generateText({
  model: __MODEL__,
  prompt,
  telemetry: {
    functionId: 'support-triage',
    metadata: { route: '/api/support' },
  },
});
```

## Context Filtering

Runtime and tool context are not automatically included in telemetry. Opt in to
specific top-level fields:

```ts
await agent.generate({
  prompt,
  runtimeContext: {
    requestId: 'req_123',
    userId: 'user_123',
  },
  toolsContext: {
    customerLookup: {
      region: 'eu',
      apiKey: process.env.CUSTOMER_API_KEY!,
    },
  },
  telemetry: {
    includeRuntimeContext: { requestId: true },
    includeToolsContext: {
      customerLookup: { region: true },
    },
  },
});
```

Filtering is shallow and only affects telemetry integrations. Tool execution,
lifecycle callbacks, and returned results still receive full context values.

## Tracing Channel

AI SDK 7 emits structured events on the Node.js `ai:telemetry` tracing channel.
Custom integrations can subscribe via `node:diagnostics_channel` and
`AI_SDK_TELEMETRY_TRACING_CHANNEL`.

Use this for observability providers that need a single subscription point
instead of per-call callbacks.

## Lifecycle Events

Prefer current callback names in v7 code:

- `onStart`
- `onStepStart`
- `onToolExecutionStart`
- `onToolExecutionEnd`
- `onStepEnd`
- `onEnd`

The exact callback set differs across core functions, `ToolLoopAgent`, and
`WorkflowAgent`. Check installed package types before adding callbacks to a
shared wrapper.

## Gotchas

- `experimental_telemetry` was renamed to `telemetry`.
- Move custom tracer setup into the `OpenTelemetry` constructor.
- `onFinish` and `onStepFinish` are v6 names; use `onEnd` and `onStepEnd` in
  v7 core code.
- Request/response bodies are excluded by default. If a telemetry integration
  needs them, explicitly opt in via `include`.
