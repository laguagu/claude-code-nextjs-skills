---
title: Canonical Examples (vercel/ai)
description: Fetch provider × feature working examples from the AI SDK repo on demand.
---

# Canonical AI SDK examples

Optional, web-only. Use [vercel/ai examples](https://github.com/vercel/ai/tree/main/examples)
when the installed docs do not show a provider-specific feature or integration.

- Core functions: `examples/ai-functions/src/<function>/<provider>/<feature>.ts`,
  e.g. `generate-text/anthropic/cache-control.ts`. List the directory before
  guessing a filename.
- Full apps: `examples/next`, `next-agent`, `next-workflow`, `harness-e2e-next`.

`main` tracks the newest major and may use unreleased APIs. For another release
read the same path at the `ai@<version>` tag. Fetch single files, not the tree.
