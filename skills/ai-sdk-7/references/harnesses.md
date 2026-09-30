---
title: AI SDK Harnesses
description: Use HarnessAgent to run Claude Code, Codex, Pi, and other agent harnesses.
---

# Harness runtime contracts

`HarnessAgent` runs an existing agent runtime, not a model provider. Its native
tools, permissions, compaction, workspace and conversation history belong to
that runtime. Packages/adapters are experimental; verify installed docs/types.

Packages: `@ai-sdk/harness` (`HarnessAgent` from `@ai-sdk/harness/agent`), one
adapter `@ai-sdk/harness-<runtime>` (`claude-code`, `codex`, `pi`, ...) and a
sandbox adapter. Bridge-backed adapters (Claude Code, Codex) need a real
network sandbox such as `@ai-sdk/sandbox-vercel`; host runtimes like Pi can use
`@ai-sdk/sandbox-just-bash`. Guides: `node_modules/ai/docs/03-ai-sdk-harnesses/`
or the [harness docs](https://ai-sdk.dev/docs/ai-sdk-harnesses/overview). Do not
copy sandbox runtime strings or broad permission defaults from a demo.

Configuration belongs to the reusable agent; live state belongs to a session
(`agent.createSession({ sessionId, resumeFrom?, sandboxSession? })`). Every
session needs an explicit lifecycle: `session.destroy()` discards
resumability; `detach()` (parks the runtime) and `stop()` (stops it) return
opaque resume state. Persist that state per authorized chat/session. A supplied
`sandboxSession` stays the caller's to destroy. Continue an unfinished resumed
turn before accepting a new prompt.

A harness consumes the latest user input against its own history. Replaying the
entire UI conversation is not equivalent to resuming its session. UI routes must
inject the session and persist its resume state at the appropriate completion
boundary; ordinary agent response helpers may need adaptation.

Built-in tool permissions are adapter/runtime policy; host SDK tools use
`toolApproval`. Do not assume one covers the other. Keep workspace setup,
credentials and host tools scoped to the session.

Skill bundles use skill-relative POSIX paths and are separate from provider
`uploadSkill`. Verify file-change/compaction dynamic parts in UI renderers and
exercise restart, resume, denial and cleanup in the selected adapter.
