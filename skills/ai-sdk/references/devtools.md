---
title: AI SDK DevTools
description: Debug AI SDK calls by inspecting captured runs and steps.
---

# AI SDK DevTools

Development only. Setup differs by major:

| `ai` | Package | Capture setup |
| --- | --- | --- |
| 6 | `@ai-sdk/devtools@ai-v6` | `wrapLanguageModel({ model, middleware: devToolsMiddleware() })` |
| 7 | `@ai-sdk/devtools` | `registerTelemetry(DevToolsTelemetry())` (or per call via `telemetry.integrations`) |

`latest` depends on `ai@7`; do not add it to a v6 app.

Runs and steps are written to `.devtools/generations.json` in the working
directory; read it directly (`jq`) to inspect prompts, tool calls, usage and
steps without the UI. `npx @ai-sdk/devtools` from the workspace that runs the
code serves a viewer on `http://localhost:4983`.

Captures contain prompts, retrieved documents, tool arguments/outputs and
provider metadata. Keep `.devtools` out of Git and public artifacts (the package
adds it to `.gitignore`; verify). Details: `node_modules/ai/docs/03-ai-sdk-core/65-devtools.mdx`.
