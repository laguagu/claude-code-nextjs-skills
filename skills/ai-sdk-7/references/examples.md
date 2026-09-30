---
title: Canonical AI SDK 7 Examples
description: Fetch current examples from the Vercel AI repository on demand.
---

# Official implementations

Optional, web-only; use installed docs first. Fetch the smallest relevant file
from the [Vercel AI examples](https://github.com/vercel/ai/tree/main/examples):

- `examples/ai-functions/src/<function>/<provider>/<feature>.ts`; v7 feature
  dirs include `harness-agent`, `workflow-agent`, `realtime`, `generate-video`,
  `upload-file`, `upload-skill`, `telemetry`. List before guessing a filename.
- Apps: `examples/next-agent`, `next-workflow`, `harness-e2e-next`.

`main` changes continuously; match its SDK/provider versions to the app (or read
the `ai@<version>` tag). Replace example model IDs with the configured
provider's verified IDs; a working demo is not a production auth/storage
contract.
