# Session Persistence & Feedback

## Database schema (Drizzle)

```ts
// lib/db/schema/chat-sessions.ts
export const chatSessions = pgTable("chat_sessions", {
  id: text("id").primaryKey(),                  // client-generated UUID
  consentAccepted: boolean("consent_accepted").notNull(),
  consentVersion: text("consent_version").notNull(),
  consentAcceptedAt: timestamp("consent_accepted_at").notNull(),
  userAgent: text("user_agent"),
  locale: text("locale"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// lib/db/schema/chat-messages.ts
export const chatMessages = pgTable("chat_messages", {
  id: serial("id").primaryKey(),
  chatId: text("chat_id").notNull()
    .references(() => chatSessions.id, { onDelete: "cascade" }),  // GDPR cascade
  messageId: text("message_id").notNull(),      // server-generated stable ID
  role: text("role").notNull(),
  content: text("content").notNull(),           // extracted text from parts
  rawParts: jsonb("raw_parts").$type<unknown[]>(), // full UIMessage.parts (tool results etc.)
  feedback: smallint("feedback"),               // null | 1 (up) | -1 (down)
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => ({
  // Prevents duplicate saves (idempotent onFinish)
  chatMessageUnique: uniqueIndex("...").on(table.chatId, table.messageId),
}));
```

## Critical ordering: session upsert BEFORE stream

The session row must exist before any message or feedback writes. `onFinish` and the feedback API both write to `chat_messages`, which FK-references `chat_sessions`.

```ts
// app/api/chat/route.ts — session upsert is awaited before createAgentUIStreamResponse
await db
  .insert(chatSessions)
  .values({ id: chatId, consentAccepted: true, ... })
  .onConflictDoUpdate({
    target: chatSessions.id,
    set: {
      updatedAt: sql`now()`,   // Use onConflictDoUpdate (NOT doNothing) to refresh updatedAt
      consentAccepted: true,   // Refreshing updatedAt keeps admin "sorted by activity" correct
      ...
    },
  });
// Then:
return createAgentUIStreamResponse({ ... });
```

## Stable server-generated message IDs

```ts
return createAgentUIStreamResponse({
  agent,
  uiMessages: messages,
  generateMessageId: createIdGenerator({ prefix: "msg", size: 16 }),
  // ^ Server generates IDs, streams them to client.
  // Client message.id === DB messageId — required for feedback to find the right row.
  ...
});
```

**Why this matters:** The feedback API uses `messageId` to update the correct row. If client-side random IDs diverge from the server-stored IDs, feedback writes to the wrong row or fails.

## onFinish: save messages after stream

```ts
onFinish: async ({ messages: finishedMessages }) => {
  if (!chatId || !finishedMessages.length) return;
  const db = getDb();
  await db
    .insert(chatMessages)
    .values(finishedMessages.map((m, index) => ({
      chatId,
      messageId: getStoredMessageId(m.id, index, m.role),
      role: m.role,
      content: m.parts                         // extract plain text
        .filter((p): p is { type: "text"; text: string } => p.type === "text")
        .map((p) => p.text)
        .join(""),
      rawParts: m.parts as unknown[],          // keep full parts for tool results
    })))
    .onConflictDoNothing();                    // idempotent — safe to retry
}
```

`rawParts` (JSONB) stores the full `UIMessage.parts[]` so chat history can restore tool results, not just text.

## Feedback retry: race window pattern

`onFinish` runs after the stream ends. The user can click feedback immediately — the DB row may not exist yet.

### API route (202 = not ready yet)

```ts
// app/api/feedback/route.ts
const result = await db
  .update(chatMessages)
  .set({ feedback })
  .where(and(eq(chatMessages.chatId, chatId), eq(chatMessages.messageId, messageId)))
  .returning({ id: chatMessages.id });

if (result.length === 0) {
  // Row not persisted yet — tell client to retry
  return NextResponse.json({ ok: false, retry: true }, { status: 202 });
}
return NextResponse.json({ ok: true });
```

### Client (exponential backoff + generation tracking)

```ts
// components/message-feedback.tsx
async function submitFeedback(
  chatId: string,
  messageId: string,
  vote: "up" | "down" | null,
  attempt: number,
  isCancelled: () => boolean,   // prevents stale retries if user changes vote
): Promise<void> {
  if (isCancelled()) return;

  const delays = [500, 1000, 2000];
  const res = await fetch("/api/feedback", {
    method: "POST",
    body: JSON.stringify({ chatId, messageId, vote }),
  });

  if (res.status === 202) {
    if (attempt < delays.length) {
      await new Promise(resolve => setTimeout(resolve, delays[attempt]));
      return submitFeedback(chatId, messageId, vote, attempt + 1, isCancelled);
    }
    throw new Error("Max retries exceeded"); // triggers optimistic UI revert
  }
}

// Optimistic UI: update state immediately, revert on error
const handleFeedback = (vote: "up" | "down") => {
  const newVote = feedback === vote ? null : vote;
  const previousFeedback = feedback;
  setFeedback(newVote);                          // optimistic

  const generation = ++generationRef.current;
  submitFeedback(chatId, messageId, newVote, 0, () => generationRef.current !== generation)
    .catch(() => setFeedback(previousFeedback)); // revert on failure
};
```

## GDPR: cascade delete

```ts
// FK with cascade delete on chat_messages and contact_requests
.references(() => chatSessions.id, { onDelete: "cascade" })

// Admin API: DELETE /api/admin/sessions/[id]
// Deletes session row → cascades to all messages and contact requests
await db.delete(chatSessions).where(eq(chatSessions.id, sessionId));
```

Consent fields (`consentAccepted`, `consentVersion`, `consentAcceptedAt`) are stored on the session, not per-message, so the consent record is erased together with the session data.

## Stream resumption (optional)

For long-running agent loops, enable reconnection after page reload with `resume: true` in useChat and `createResumableStreamContext` on the server. Requires a stream store (Redis). See AI SDK docs: ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams

