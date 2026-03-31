---
name: nextjs-chatbot
description: "Production-grade Next.js chatbot builder. Covers tool calling with human-in-the-loop (HITL) approval, PostgreSQL session persistence, GDPR consent gating, SQL-first search, per-tool UI rendering, message feedback, and follow-up suggestions. Use when building chat apps, conversational AI interfaces, customer support bots, or any chatbot needing database-backed sessions, tool approval workflows, consent gating, or custom tool output components."
---

# Next.js Chatbot

Opinionated blueprint for production chatbots. Focuses on patterns **not** covered by `/ai-sdk-6`, `/ai-elements`, or `/nextjs-shadcn` — use those skills for general SDK, component, and framework questions.

## Stack defaults

- **Runtime:** bun
- **Model:** `gpt-5.4` with `reasoningEffort: "none"`
- **AI SDK:** `ai@6` — `ToolLoopAgent`, `createAgentUIStreamResponse`
- **UI:** shadcn/ui + ai-elements (see `/ai-elements` for component docs)
- **ORM:** Drizzle + PostgreSQL
- **State:** Zustand for client-side chat state (consent, session, suggestions)
- **Attachments:** See `/ai-elements` Attachments component for file upload

## Recommended MCP servers

Add to your `.claude/settings.json` or IDE MCP config for better dev experience:

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    },
    "ai-elements": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://registry.ai-sdk.dev/api/mcp"]
    }
  }
}
```

- **next-devtools** — Next.js route inspection, build diagnostics, config validation. See [nextjs.org/docs/app/guides/mcp](https://nextjs.org/docs/app/guides/mcp)
- **ai-elements** — Browse and search ai-elements component registry with up-to-date docs and examples

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

## Building a new chatbot — checklist

- [ ] Scaffold with `/ai-app` or `bunx --bun shadcn@latest create`
- [ ] Install: `bun add ai @ai-sdk/react @ai-sdk/openai zod drizzle-orm postgres`
- [ ] Install ai-elements: `bunx --bun ai-elements@latest` → Conversation, Message, PromptInput, Loader, Shimmer
- [ ] Create agent: `lib/ai/agent.ts` with ToolLoopAgent
- [ ] Create route: `app/api/chat/route.ts` with createAgentUIStreamResponse
- [ ] Create chat page using ai-elements components
- [ ] Add tools: one tool at a time, with UI renderer per tool
- [ ] Add persistence: DB schema → session upsert → onFinish save → history load
- [ ] Add consent gating (if needed): privacy wall → consent check in route
- [ ] Add feedback (if needed): thumbs up/down → 202 retry pattern
- [ ] Add HITL approval (if needed): needsApproval tool → approval UI
- [ ] Add suggestions (if needed): POST /api/suggestions → display after response

## Verification

After each milestone, verify:

1. `bun dev` — app starts without errors
2. Send a message → assistant responds with streaming text
3. Tool calls → correct UI renders per tool state
4. DB check: `SELECT * FROM chat_sessions` / `chat_messages` has rows
5. Feedback: click thumbs up → DB row updated (may need retry)
6. Reload page → chat history restores from DB

## Key patterns (reference files)

- **HITL approval** — tool with `needsApproval: true`, 5-state render machine → [hitl.md](hitl.md)
- **Session persistence + feedback retry** — stable IDs, onFinish, race window → [persistence.md](persistence.md)
- **SQL-first search** — FTS + trigram vs RAG decision → [search.md](search.md)
- **Tool UI rendering** — `renderToolState<T>` factory, per-tool components → [tool-rendering.md](tool-rendering.md)
- **Follow-up suggestions** — generateText + Output.object after each response → [suggestions.md](suggestions.md)

## When to use vs other skills

| Skill | Use for |
|---|---|
| `/nextjs-chatbot` | HITL approval, session DB, feedback retry, SQL search, per-tool UI |
| `/ai-sdk-6` | General SDK: `generateText`, `streamText`, tool definitions, structured output |
| `/ai-elements` | Chat UI components: `Message`, `Shimmer`, `Sources`, `MessageAction` |
| `/nextjs-shadcn` | Next.js app setup, shadcn components, routing, layouts |
| `/postgres-semantic-search` | Advanced search: hybrid FTS+vector, BM25, reranking, HNSW tuning |
