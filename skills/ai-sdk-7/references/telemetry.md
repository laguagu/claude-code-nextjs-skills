---
title: AI SDK 7 Telemetry
description: OpenTelemetry registration, tracing channel, context filtering, and lifecycle events.
---

# Telemetry boundaries

Register a telemetry integration once at app startup. For OpenTelemetry use
`@ai-sdk/otel` with `registerTelemetry`; a Next.js app may register from its
instrumentation entry point.

Once registered, telemetry is enabled by default; per-call `telemetry.isEnabled`
can opt out. Without a registered integration it is disabled. Verify input and
output capture settings for the app's data policy.

Runtime/tool context is not included automatically. Context field filtering is
shallow and affects telemetry only; execution, callbacks and result objects
can still receive full values. Do not treat filtering as redaction everywhere.

Request/response bodies are excluded by default; opt in only where needed and
safe. Callback sets differ by core function/agent type. Custom integrations can
use the SDK's diagnostics tracing channel rather than per-call wrappers.

Read installed `@ai-sdk/otel` docs/types and
[telemetry docs](https://ai-sdk.dev/docs/ai-sdk-core/telemetry) for exact capture
defaults and integration options.
