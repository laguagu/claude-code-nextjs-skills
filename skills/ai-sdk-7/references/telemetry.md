---
title: AI SDK 7 Telemetry
description: OpenTelemetry registration, tracing channel, context filtering, and lifecycle events.
---

# Telemetry boundaries

OpenTelemetry is no longer built into `ai`. Register once at startup:
`registerTelemetry(new OpenTelemetry())` (`registerTelemetry` from `ai`,
`OpenTelemetry` from `@ai-sdk/otel`; custom tracer goes in its constructor). In
Next.js, do it in `instrumentation.ts` next to the OTel provider setup.

Once an integration is registered, every call emits telemetry; opt out per call
with `telemetry: { isEnabled: false }`. With none registered, nothing is
emitted. `recordInputs`/`recordOutputs` default to true, so prompts and outputs
reach the exporter unless disabled; match the app's data policy.

Context is excluded unless allow-listed with `telemetry.includeRuntimeContext`
/ `includeToolsContext`. That filtering is shallow and telemetry-only;
execution, callbacks and result objects still see full values.

Request/response bodies are excluded by default; opt in only where needed and
safe. Callback sets differ by core function/agent type. Custom integrations can
subscribe to `AI_SDK_TELEMETRY_TRACING_CHANNEL` rather than wrapping calls.

Read `node_modules/ai/docs/03-ai-sdk-core/60-telemetry.mdx` (`@ai-sdk/otel`
ships types only) or the [telemetry docs](https://ai-sdk.dev/docs/ai-sdk-core/telemetry).
