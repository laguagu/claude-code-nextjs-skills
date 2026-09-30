---
title: AI SDK Harnesses
description: Use HarnessAgent to run Claude Code, Codex, Pi, and other agent harnesses.
---

# Harness runtime contracts

`HarnessAgent` runs an existing agent runtime, not a model provider. Its native
tools, permissions, compaction, workspace and conversation history belong to
that runtime. Packages/adapters are experimental; verify installed docs/types.

Choose an adapter and compatible sandbox from
[harness docs](https://ai-sdk.dev/docs/ai-sdk-harnesses/overview). Bridge-backed
adapters require a reachable network sandbox; lighter host runtimes may differ.
Do not copy sandbox runtime strings or broad permission defaults from a demo.

Configuration belongs to the reusable agent; live state belongs to a session.
Every session needs an explicit lifecycle: destroy discards resumability,
detach/stop produce opaque resume state with different runtime behavior.
Persist that state per authorized chat/session. Continue an unfinished resumed
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
