# Follow-up Suggestions

Generate contextual follow-up questions after each assistant response. Improves engagement by guiding users toward relevant next steps.

## API route

```ts
// app/api/suggestions/route.ts
import { NextResponse } from "next/server";
import { z } from "zod";
import { generateSuggestions } from "@/lib/ai/generate-suggestions";

export const maxDuration = 30;

const requestSchema = z.object({
  question: z.string().min(1).max(5000),
  answer: z.string().min(1).max(10000),
});

export async function POST(request: Request) {
  try {
    const parsed = requestSchema.safeParse(await request.json());
    if (!parsed.success) {
      return NextResponse.json({ error: "Invalid input" }, { status: 400 });
    }

    const suggestions = await generateSuggestions(parsed.data.question, parsed.data.answer);
    return NextResponse.json({ suggestions });
  } catch (error) {
    console.error("Error generating suggestions:", error);
    return NextResponse.json({ error: "Failed to generate suggestions" }, { status: 500 });
  }
}
```

## Generation logic: generateText + Output.object

Use a cheap, fast model (e.g. `gpt-4o-mini`) — suggestions are non-critical and latency matters more than quality.

```ts
// lib/ai/generate-suggestions.ts
import { generateText, Output } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";

const suggestionsSchema = z.object({
  questions: z.array(z.string()).max(3)
    .describe("Follow-up questions the user might want to ask"),
});

export async function generateSuggestions(
  question: string,
  answer: string,
): Promise<string[]> {
  try {
    const { output } = await generateText({
      model: openai("gpt-4o-mini"),
      output: Output.object({ schema: suggestionsSchema }),
      prompt: `Based on this conversation, suggest 2-3 concise follow-up questions.

User question: ${question}

Assistant answer: ${answer}

Generate questions that:
- Are relevant to the discussed topic
- Help the user learn more, get details, or take the next step
- Are concise (under 10 words each)
- Are in the same language as the user's question

Return 2-3 follow-up questions.`,
    });

    return output?.questions ?? [];
  } catch (error) {
    console.error("Error generating suggestions:", error);
    return []; // Fail silently — suggestions are not critical
  }
}
```

## Client integration

### Fetch suggestions after each response

Call the suggestions API in the `onFinish` callback of `useChat`. Store results in Zustand or local state, clear when user sends a new message.

```ts
// hooks/use-chat.ts or chat component
const { messages, sendMessage } = useChat({
  transport: new DefaultChatTransport({ api: "/api/chat" }),
  onFinish: async ({ message, messages }) => {
    // Extract last user question + assistant answer
    const lastUserMsg = [...messages].reverse().find(m => m.role === "user");
    const question = lastUserMsg?.parts
      .filter((p): p is { type: "text"; text: string } => p.type === "text")
      .map(p => p.text).join("") ?? "";
    const answer = message.parts
      .filter((p): p is { type: "text"; text: string } => p.type === "text")
      .map(p => p.text).join("") ?? "";

    if (question && answer) {
      try {
        const res = await fetch("/api/suggestions", {
          method: "POST",
          body: JSON.stringify({ question, answer }),
        });
        const { suggestions } = await res.json();
        setSuggestions(suggestions); // Zustand or setState
      } catch {
        // Fail silently
      }
    }
  },
});
```

### Display with ai-elements Suggestion component

```tsx
import { Suggestion } from "@/components/ai-elements/suggestion";

{suggestions.length > 0 && (
  <div className="flex flex-wrap gap-2 px-4 py-2">
    {suggestions.map((text, i) => (
      <Suggestion
        key={i}
        onClick={() => {
          sendMessage({ text });
          setSuggestions([]); // Clear after use
        }}
      >
        {text}
      </Suggestion>
    ))}
  </div>
)}
```

### Clear suggestions on new user message

Reset suggestions when the user sends a new message to avoid stale suggestions:

```ts
const handleSend = (text: string) => {
  setSuggestions([]); // Clear before sending
  sendMessage({ text });
};
```

## Gotchas

- Use a cheap model — suggestions run after every response, cost adds up fast
- Fail silently — never block the chat UI if suggestions fail
- Clear on send — stale suggestions from a previous turn are confusing
- Language matching — instruct the model to match the user's language

