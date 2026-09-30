---
title: AI SDK DevTools
description: Debug AI SDK calls by inspecting captured runs and steps.
---

# AI SDK DevTools

Use DevTools when captured model requests, responses and steps would help diagnose a development issue. Choose an `@ai-sdk/devtools` release compatible with the project's installed AI SDK major; inspect its current exports, middleware setup and CLI rather than copying a pinned provider model.

Keep instrumentation development-only. Captures can contain prompts, retrieved documents, tool arguments, outputs and provider metadata. Exclude capture files from Git and public artifacts; apply the same data policy as application logs.

Find setup and capture format in the [official DevTools guide](https://ai-sdk.dev/docs/ai-sdk-core/devtools) or the installed package docs/source. Follow the repository's package manager. Verify where the selected release stores captures and which address its viewer binds to before opening or sharing it.

DevTools describes what happened in a call; it does not replace testing authorization, restored conversation replay or the production stream path.
