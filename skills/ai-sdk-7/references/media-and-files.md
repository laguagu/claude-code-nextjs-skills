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
or opaque references against the provider's contract. Inline tool results use
`{ type: 'file', mediaType, data: { type: 'data', data } }` in v7; retain handling
of deprecated `file-data` in persisted/legacy outputs and `reasoning-file` parts
in serializers/renderers.

Realtime APIs are experimental. Create scoped ephemeral browser credentials on
the server; keep long-lived provider keys there. Verify reconnect and
client-driven tool execution behavior for the chosen provider.

Realtime facts the docs do not state (`experimental_useRealtime`, 7.0.159, OpenAI token sessions):

- `connect({ stream })` only stores the stream. Call `startAudioCapture(stream)` once `status` is
  `connected`, or no `input_audio_buffer.append` frame is ever sent and no error comes.
- `response-create` with `instructions` replaces the session's instructions for that response.
- `sessionConfig.providerOptions` is copied into the session as it is, so options go at its top level:
  `providerOptions: { reasoning: { effort: "minimal" } }`, not under `openai`. On `gpt-realtime-2.1`
  this took the wait before a tool call from about 3.3 s to under a second.
- The hook gives no audio levels. Take them from the PCM in `audio-delta` events through `onEvent`.

Video generation and media downloads need the actual provider limits, bounded
sizes and cancellation. Do not bake demo model IDs or download behavior into a
shared wrapper.

Read the provider documentation and
[v7 migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-7-0)
for file-part changes; locate current realtime/video APIs in the installed docs.
