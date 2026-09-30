---
title: Media, Files, Realtime, and Video in AI SDK 7
description: Provider file uploads, skill uploads, realtime sessions, and video generation.
---

# Files, skills, realtime and video

Check the configured provider's capabilities before choosing an API. These
features are not universally supported across providers or interchangeable IDs.

| Feature | Export | Local guide (`node_modules/ai/docs/03-ai-sdk-core/`) |
| --- | --- | --- |
| Provider file reference | `uploadFile` (`ai`) | `39-file-uploads.mdx` |
| Provider-managed skills | `uploadSkill` (`ai`) | `41-skill-uploads.mdx` |
| Realtime voice | `experimental_useRealtime` (`@ai-sdk/react`), `experimental_getRealtimeToolDefinitions` (`ai`) | `36-realtime.mdx` |
| Video | `experimental_generateVideo` (`ai`) | `38-video-generation.mdx` |

`uploadFile` returns a provider reference for reuse with a compatible provider.
Provider skills are separate from HarnessAgent instruction bundles.

Canonical file parts use `type: 'file'`, `data` and `mediaType`. V7 accepts
a full IANA type or a top-level segment such as `image`, with subtype detection
from inline bytes where possible. Use a precise type when known; validate remote
or opaque references against the provider's contract. Handle `file-data` tool
results and `reasoning-file` parts in serializers/renderers.

Realtime: create scoped ephemeral browser credentials on the server; keep
long-lived provider keys there. Verify reconnect and client-driven tool
execution behavior for the chosen provider.

Video generation and media downloads need the actual provider limits, bounded
sizes and cancellation. Do not bake demo model IDs or download behavior into a
shared wrapper. File-part changes: [migration reference](migration-v6-to-v7.md).
