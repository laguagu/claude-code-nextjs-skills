---
title: AI SDK DevTools
description: Debug AI SDK calls by inspecting captured runs and steps.
---

# AI SDK DevTools

Use DevTools when captured model requests, responses and steps would help diagnose a development issue. Match `@ai-sdk/devtools` to the installed SDK major (`latest` for v7, `@ai-sdk/devtools@ai-v6` for v6):

| SDK | Capture setup |
| --- | --- |
| v6 | `wrapLanguageModel({ model, middleware: devToolsMiddleware() })` |
| v7 | `registerTelemetry(DevToolsTelemetry())`, or `telemetry.integrations` per call |

Read `ai/docs/03-ai-sdk-core/65-devtools.mdx`. The viewer defaults to
`http://localhost:4983`; captures are `.devtools/generations.json` in the app
working directory and can be inspected directly without the viewer.

Keep instrumentation development-only. Captures can contain prompts, retrieved documents, tool arguments, outputs and provider metadata. Exclude capture files from Git and public artifacts; apply the same data policy as application logs.

Find setup and capture format in the [official DevTools guide](https://ai-sdk.dev/docs/ai-sdk-core/devtools) or the installed package docs/source. Follow the repository's package manager. Verify where the selected release stores captures and which address its viewer binds to before opening or sharing it.

DevTools describes what happened in a call; it does not replace testing authorization, restored conversation replay or the production stream path.
