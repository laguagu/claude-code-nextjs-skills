---
name: nextjs-chatbot
description: "Production-grade Next.js chatbot with AI SDK v6 (ToolLoopAgent), HITL tool approval, PostgreSQL session persistence, GDPR consent gating, SQL-first search, and per-tool UI rendering. Use when building chatbots that need database-backed sessions, tool calling with human-in-the-loop approval, consent gating, feedback, or custom tool output components. Reference implementation: fair-helpdesk project."
---

# Next.js Chatbot

Opinionated blueprint for production chatbots. Focuses on patterns **not** covered by `/ai-sdk-6`, `/ai-elements`, or `/nextjs-shadcn` — use those skills for general SDK, component, and framework questions.

**Reference implementation:** `c:\hh-tyo\fair\helpdesk-chatbot`

## Stack defaults

- **Runtime:** bun
- **Model:** `gpt-5.4` with `reasoningEffort: "none"`
- **AI SDK:** `ai@6` — `ToolLoopAgent`, `createAgentUIStreamResponse`
- **UI:** shadcn/ui + ai-elements (see `/ai-elements` for component docs)
- **ORM:** Drizzle + PostgreSQL
- **Deploy:** CSC Rahti 2 / OpenShift (see `/fair-helpdesk` for FAIR-specific deploy)

## Agent setup

```ts
// lib/ai/my-agent.ts
import { openai } from "@ai-sdk/openai";
import { ToolLoopAgent, InferAgentUIMessage, stepCountIs } from "ai";

export function createAgent(opts?: { model?: LanguageModel }) {
  return new ToolLoopAgent({
    model: opts?.model ?? openai("gpt-5.4"),
    instructions,          // system prompt string
    providerOptions: { openai: { reasoningEffort: "none" } },
    tools,                 // { toolName: tool(...) }
    stopWhen: stepCountIs(10),
  });
}

export const agent = createAgent();
export type AgentUIMessage = InferAgentUIMessage<typeof agent>;
```

Wrap model with `devToolsMiddleware()` from `@ai-sdk/devtools` in development.

Export a factory (`createAgent`) in addition to the singleton — needed for benchmarks with different models.

## Route handler

```ts
// app/api/chat/route.ts
export const maxDuration = 60;

export async function POST(request: Request) {
  const { messages, chatId, ...consentData } = await request.json();

  // 1. Validate consent — block if missing
  if (!consentData.consentAccepted) {
    return new Response(JSON.stringify({ error: "Consent required" }), { status: 403 });
  }

  // 2. Upsert session — MUST be awaited before streaming starts
  await db.insert(chatSessions).values({ id: chatId, ... })
    .onConflictDoUpdate({ target: chatSessions.id, set: { updatedAt: sql`now()` } });

  // 3. Stream
  return createAgentUIStreamResponse({
    agent,
    uiMessages: messages,
    generateMessageId: createIdGenerator({ prefix: "msg", size: 16 }),
    consumeSseStream: ({ stream }) => consumeStream({ stream }),
    experimental_transform: smoothStream({ delayInMs: 15, chunking: "word" }),
    onFinish: async ({ messages: finished }) => {
      // Save to DB after stream — see persistence.md
    },
  });
}
```

## Adding a new tool

1. Create `lib/ai/tools/my-tool.ts` with `tool()` from `ai`
2. Export from `lib/ai/tools/index.ts`
3. Add to `tools` object in the agent file
4. Document in the agent's `instructions` string
5. Add UI renderer in `chat-message.tsx` (handle `tool-myTool` part type)

## Key patterns (reference files)

- **HITL approval** — tool with `needsApproval: true`, 5-state render machine → [hitl.md](hitl.md)
- **Session persistence + feedback retry** — stable IDs, onFinish, race window → [persistence.md](persistence.md)
- **SQL-first search** — FTS + trigram vs RAG decision → [search.md](search.md)
- **Tool UI rendering** — `renderToolState<T>` factory, per-tool components → [tool-rendering.md](tool-rendering.md)

## When to use vs other skills

| Skill | Use for |
|---|---|
| `/nextjs-chatbot` | HITL approval, session DB, feedback retry, SQL search, per-tool UI |
| `/ai-sdk-6` | General SDK: `generateText`, `streamText`, tool definitions, structured output |
| `/ai-elements` | Chat UI components: `Message`, `Shimmer`, `Sources`, `MessageAction` |
| `/nextjs-shadcn` | Next.js app setup, shadcn components, routing, layouts |
