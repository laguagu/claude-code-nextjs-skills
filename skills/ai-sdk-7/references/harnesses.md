---
title: AI SDK Harnesses
description: Use HarnessAgent to run Claude Code, Codex, Pi, and other agent harnesses.
---

# AI SDK Harnesses

AI SDK harnesses run established agent runtimes through a single AI SDK surface.
A harness is not a model provider. It owns a runtime with its own tools,
workspace state, permissions, compaction, and session history.

Harness packages are experimental. Verify installed package docs and types
before adding production abstractions around them.

## When to Use a Harness

Use `HarnessAgent` when the existing runtime should drive the task:

- Coding agents that inspect and edit a sandboxed workspace.
- Runtimes with native tools and permission flows.
- Multi-turn sessions where the harness owns conversation history.
- Tasks where preserving Claude Code, Codex, Pi, Deep Agents, or OpenCode
  behavior matters more than direct model-loop control.

Use `ToolLoopAgent`, `generateText`, or `streamText` when you need direct control
over model settings, tool loop behavior, structured output, or provider calls.

## Install

Install the core package, one adapter, and a sandbox provider:

```bash
bun add @ai-sdk/harness @ai-sdk/harness-claude-code @ai-sdk/sandbox-vercel
```

Bridge-backed harnesses such as Claude Code and Codex require a real network
sandbox provider. Host-runtime harnesses may support lighter sandboxes; check
the adapter docs.

## Create a HarnessAgent

```ts
import { HarnessAgent } from '@ai-sdk/harness/agent';
import { claudeCode } from '@ai-sdk/harness-claude-code';
import { createVercelSandbox } from '@ai-sdk/sandbox-vercel';

export const agent = new HarnessAgent({
  harness: claudeCode,
  sandbox: createVercelSandbox({
    runtime: 'node24',
    ports: [4000],
  }),
  instructions:
    'You are a careful coding assistant. Prefer small diffs and explain tradeoffs.',
});
```

Construct the agent at module scope. It holds configuration, not live state.
Live state belongs to a `HarnessAgentSession`.

## Run a Turn

```ts
const session = await agent.createSession();

try {
  const result = await agent.stream({
    session,
    prompt: 'Inspect the repository and summarize the test setup.',
  });

  for await (const part of result.stream) {
    if (part.type === 'text-delta') {
      process.stdout.write(part.text);
    }
  }
} finally {
  await session.destroy();
}
```

`generate()` returns an AI SDK `GenerateTextResult`; `stream()` returns an AI
SDK `StreamTextResult`.

## Session Lifecycle

End every session explicitly:

- `destroy()` stops the runtime and discards resumability.
- `detach()` parks the runtime/sandbox, returns resume state, and can keep the
  sandbox warm for a later attach.
- `stop()` saves resume state, then stops the runtime/sandbox.
- `suspendTurn()` is for advanced active-turn handoff across a process boundary.

For server routes, use a stable `sessionId` and persist the opaque resume state:

```ts
const resumeState = await loadResumeState(chatId);
const session = await agent.createSession(
  resumeState
    ? { sessionId: chatId, resumeFrom: resumeState }
    : { sessionId: chatId },
);
```

If resume state contains an unfinished turn, continue it with
`continueStream()` or `continueGenerate()` before accepting a new prompt.

## Messages and History

Harness sessions own their native conversation history. When passed `messages`
or a message-array prompt, `HarnessAgent` treats the latest user message as the
fresh turn input. It does not replay the entire prior conversation like a model
call usually does.

In chat routes, persist and resume the harness session instead of relying on
UI-message replay.

## Sandbox Preparation

Use `sandboxConfig` for workspace setup:

- `workDir`: relative working directory for sessions.
- `onBootstrap`: expensive setup used for reusable templates; provide a
  `bootstrapHash` and change it when setup output should invalidate snapshots.
- `onSession`: per-session lightweight files or configuration.

Use `prepareHarnessSandboxTemplate()` to prepare reusable sandbox templates
ahead of time.

## Tools and Permissions

Harnesses expose two tool surfaces:

- Built-in tools executed by the harness runtime, such as `read`, `write`,
  `edit`, `bash`, `grep`, `glob`, or `webSearch`.
- Host-executed AI SDK tools passed through the `tools` setting.

Use `permissionMode` for built-in harness tools:

- `allow-all`: allow reads, edits, and shell commands.
- `allow-edits`: allow reads and edits; request shell approval where supported.
- `allow-reads`: allow reads; request edit/shell approval where supported.

Use `toolApproval` for host-executed tools.

## Skills

Pass reusable instruction bundles with `skills`:

```ts
const agent = new HarnessAgent({
  harness: claudeCode,
  sandbox,
  skills: [
    {
      name: 'careful-refactors',
      description: 'Make small, low-risk code changes.',
      content:
        'Prefer minimal diffs. Preserve public APIs. Read references/checklist.md before editing.',
      files: [
        {
          path: 'references/checklist.md',
          content: `# Checklist

- Preserve APIs.
- Run focused tests.`,
        },
      ],
    },
  ],
});
```

Skill file paths are skill-relative POSIX paths. Reference additional files from
`content` when the harness should read them.

## UI Integration

Harness streams are compatible with AI SDK UI streams, but session management is
different from model chat routes.

Route outline:

1. Read `id` and `messages` from the request.
2. Convert UI messages with `convertToModelMessages`.
3. Resume or create a `HarnessAgentSession` for the chat id.
4. Call `agent.stream({ session, messages })`.
5. Return `createUIMessageStreamResponse({ stream: toUIMessageStream(...) })`.
6. Persist `session.detach()` in `onEnd`.

Do not call `createAgentUIStreamResponse` directly with `HarnessAgent` unless
you wrap the agent to inject the required session.

## Adapters

Official adapter packages include Claude Code, Codex, Deep Agents, OpenCode,
and Pi. Adapter-specific settings belong on the adapter factory, for example a
Codex reasoning setting on the Codex adapter constructor.

## Gotchas

- Harness built-in tool calls are executed by the runtime, not your host
  process. Stream parts can be provider-executed.
- File changes and compaction can surface as dynamic provider-executed tool
  parts; check `part.dynamic`.
- Persist opaque resume state, not your own reconstruction of native session
  internals.
- Bridge-backed adapters need sandbox credentials and network reachability.
