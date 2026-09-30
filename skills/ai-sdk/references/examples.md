---
title: Canonical Examples (vercel/ai)
description: Fetch provider × feature working examples from the AI SDK repo on demand.
---

# Canonical AI SDK examples

Use [vercel/ai examples](https://github.com/vercel/ai/tree/main/examples) for a provider-specific feature or integration that the installed package docs do not explain sufficiently.

Discover the current tree before constructing a path. The `examples/ai-functions/src` directory groups many core examples by function and provider, but coverage and filenames change. Read the example's imports, package manifest and runtime requirements together.

Match the repository tag or commit to the project's AI SDK major and compatible provider packages. Examples on `main` may use unreleased APIs; they are evidence of that revision's usage, not proof that an installed version supports it.

Fetch the relevant files and their dependencies rather than bringing the whole examples tree into the application. Keep the application's authorization, data policy, transport and hosting requirements when adapting an example.
