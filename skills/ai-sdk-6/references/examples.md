---
title: Canonical Examples (vercel/ai)
description: Fetch provider × feature working examples from the AI SDK repo on demand.
---

# Canonical Examples

The `vercel/ai` repo maintains runnable examples for every supported AI SDK function, provider, and feature combination. These fill the gap between conceptual docs in `node_modules/ai/docs/` and high-level API reference on ai-sdk.dev — working, copy-pasteable code that tracks the current `main` branch (v6 APIs).

> **Do not clone the repo.** Fetch individual files on demand via WebFetch or `gh api`.

## Path Pattern

```
examples/ai-functions/src/{function}/{provider}/{feature}.ts
```

## Top-Level Categories

| Category        | Directories                                                  |
| --------------- | ------------------------------------------------------------ |
| Text generation | `generate-text`, `stream-text`, `stream-text-custom-loop`    |
| Agent           | `agent`                                                      |
| Embedding       | `embed`, `embed-many`, `rerank`                              |
| Media           | `generate-image`, `generate-video`, `generate-speech`, `transcribe` |
| Tooling         | `tools`, `middleware`, `registry`, `telemetry`, `gateway`    |
| Integration     | `complex`, `upload-file`                                     |

Each function directory splits by provider: `anthropic`, `openai`, `google`, `amazon`, `azure`, `bedrock`, `cohere`, `groq`, `xai`, `deepseek`, `fireworks`, `huggingface`, and more.

## Discovery

List files under a provider subdirectory:

```bash
gh api repos/vercel/ai/contents/examples/ai-functions/src/{function}/{provider} \
  --jq '[.[] | select(.type=="file") | .name]'
```

Or fetch the GitHub tree page with WebFetch:

```
https://github.com/vercel/ai/tree/main/examples/ai-functions/src/{function}/{provider}
```

## Fetching a Single File

Use the raw URL:

```
https://raw.githubusercontent.com/vercel/ai/main/examples/ai-functions/src/{function}/{provider}/{feature}.ts
```

Concrete example — Anthropic prompt caching:

```
https://raw.githubusercontent.com/vercel/ai/main/examples/ai-functions/src/generate-text/anthropic/cache-control.ts
```

## When to Reach for This

- Provider-specific features (Anthropic `adaptive-thinking`, OpenAI `computer-use`, Google grounding)
- Version-suffixed feature flags (e.g. `code-execution-20250825.ts`)
- Multi-step agent patterns not covered in docs
- Middleware compositions
- Streaming edge cases (tool-call streaming, reasoning streams)

## When Not to Reach for This

- Basic API usage — `node_modules/ai/docs/` is faster
- High-level API reference — ai-sdk.dev is faster
- Examples assume you already know the API; they are working patterns, not tutorials
