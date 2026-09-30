---
title: Media, Files, Realtime, and Video in AI SDK 7
description: Provider file uploads, skill uploads, realtime sessions, and video generation.
---

# Files, skills, realtime and video

Check the configured provider's capabilities before choosing an API. These
features are not universally supported across providers or interchangeable IDs.

`uploadFile` returns a provider reference for reuse with a compatible provider;
`uploadSkill` uploads provider-managed skill files. Provider skills are separate
from HarnessAgent instruction bundles.

Canonical file parts use `type: 'file'`, `data` and `mediaType`. V7 accepts
a full IANA type or a top-level segment such as `image`, with subtype detection
from inline bytes where possible. Use a precise type when known; validate remote
or opaque references against the provider's contract. Handle `file-data` tool
results and `reasoning-file` parts in serializers/renderers.

Realtime APIs are experimental. Create scoped ephemeral browser credentials on
the server; keep long-lived provider keys there. Verify reconnect and
client-driven tool execution behavior for the chosen provider.

Video generation and media downloads need the actual provider limits, bounded
sizes and cancellation. Do not bake demo model IDs or download behavior into a
shared wrapper.

Read the provider documentation and
[v7 migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-7-0)
for file-part changes; locate current realtime/video APIs in the installed docs.
