---
title: Media, Files, Realtime, and Video in AI SDK 7
description: Provider file uploads, skill uploads, realtime sessions, and video generation.
---

# Media, Files, Realtime, and Video

AI SDK 7 adds provider-agnostic surfaces for repeated file use, provider skill
uploads, realtime sessions, and video generation. Treat provider support as
capability-dependent and verify current provider docs before implementation.

## Provider File Uploads

Use `uploadFile` when a workflow repeatedly sends the same large artifact to a
provider. Upload once, then pass the provider reference in later model calls.

```ts
import { uploadFile, streamText } from 'ai';
import { openai } from '@ai-sdk/openai';
import { readFileSync } from 'node:fs';

const { providerReference } = await uploadFile({
  api: openai.files(),
  data: readFileSync('./photo.png'),
  filename: 'photo.png',
});

const result = await streamText({
  model: __MODEL__,
  messages: [
    {
      role: 'user',
      content: [
        { type: 'text', text: 'Describe this image.' },
        {
          type: 'file',
          mediaType: 'image/png',
          data: providerReference,
        },
      ],
    },
  ],
});
```

## Provider Skill Uploads

Use `uploadSkill` when a provider-managed container can reuse a skill across
requests instead of receiving the skill files inline every time.

```ts
import { uploadSkill } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { readFileSync } from 'node:fs';

const { providerReference } = await uploadSkill({
  api: anthropic.skills(),
  files: [
    {
      path: 'my-skill/SKILL.md',
      content: readFileSync('./my-skill/SKILL.md'),
    },
  ],
  displayTitle: 'My Skill',
});
```

Provider skill uploads are separate from `HarnessAgent` skills. Harness skills
are instruction bundles passed to the harness runtime.

## File Content Parts

For new code, prefer canonical file parts:

```ts
{
  type: 'file',
  mediaType: 'image/png',
  data: bytesOrProviderReference,
}
```

`mediaType` is a full IANA media type (e.g. `image/png`, `application/pdf`,
`audio/mpeg`), not a bare category like `image`.

Update validators and renderers for:

- `file-data` tool results instead of removed `media` tool results.
- canonical `file` parts instead of legacy image/file variants.
- `reasoning-file` parts for files returned as part of model reasoning.

## Realtime

AI SDK 7 includes experimental provider-agnostic realtime support for browser
WebSocket sessions. It supports server-created ephemeral tokens, realtime
providers, and a React realtime hook that returns `UIMessage[]`.

Use realtime for voice agents, low-latency interactive sessions, and
client-driven tool calls. Keep provider-specific WebSocket details behind the
AI SDK realtime abstraction where possible.

## Video Generation

Use `experimental_generateVideo` for video generation after checking provider
support and size/download limits:

```ts
import { experimental_generateVideo as generateVideo } from 'ai';

const { videos } = await generateVideo({
  model: __VIDEO_MODEL__,
  prompt: 'A product demo animation.',
  aspectRatio: '16:9',
});
```

Model IDs and provider support move quickly; verify current docs before coding.

## Gotchas

- File uploads return provider references, not universal file IDs.
- Only use a provider reference with providers that support it.
- Do not assume realtime hooks or video APIs are stable across providers.
- Bound download sizes and abort long media operations.
