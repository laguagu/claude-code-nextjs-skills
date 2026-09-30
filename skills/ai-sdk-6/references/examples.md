---
title: Canonical Examples (vercel/ai)
description: Fetch provider × feature working examples from the AI SDK repo on demand.
---

# AI SDK 6 examples

Use the installed docs first. For provider-specific behavior, locate the
relevant [Vercel AI v6 example](https://github.com/vercel/ai/tree/ai%406.0.297/examples)
and select a tag/commit matching the app's installed release.

Repository main now targets newer code. Do not copy its `instructions`,
`isStepCount`, `onEnd` or stateless response helpers into a v6 app without
checking compatibility.

Fetch only the needed file, verify its provider package and replace demo model
IDs/configuration with the app's actual values. Examples demonstrate API usage;
they do not establish authentication, storage or operational requirements.
