---
title: Canonical AI SDK 7 Examples
description: Fetch current examples from the Vercel AI repository on demand.
---

# Canonical Examples

Use installed docs first. When you need a runnable provider-specific pattern,
fetch one file from the Vercel AI repository instead of cloning the repo.

## Search the Repo

List candidate files with the GitHub API:

```bash
gh api repos/vercel/ai/git/trees/main?recursive=1 --jq '.tree[].path | select(startswith("examples/")) | select(test("generate-text|stream-text|agent|telemetry|upload-file|generate-video|realtime|harness"))'
```

Or inspect a directory:

```bash
gh api repos/vercel/ai/contents/examples/ai-functions/src/generate-text --jq '[.[] | .name]'
```

## Fetch One File

Use the raw URL pattern:

```txt
https://raw.githubusercontent.com/vercel/ai/main/examples/ai-functions/src/{function}/{provider}/{feature}.ts
```

## When Examples Help

- Provider-specific features such as caching, grounding, or code execution.
- Realtime, file upload, video, and other capability-dependent APIs.
- Telemetry setup and custom integrations.
- Streaming edge cases.
- Harness examples if the docs/source tree has a matching example.

## Gotchas

- Examples track the repository main branch. Compare with the installed package
  version before copying code.
- Do not use example model IDs blindly. Check the project's provider config or
  current provider catalog.
- Do not clone the full repo just to read one example.
