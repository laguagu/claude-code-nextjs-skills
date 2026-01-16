# Core Functions

## generateText

Non-interactive text generation for automation tasks, agents, and structured output.

```typescript
import { generateText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const { text, usage, finishReason } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "Write a vegetarian lasagna recipe for 4 people.",
});
```

### With System Prompt

```typescript
const { text } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  system: "You are an expert chef specializing in Italian cuisine.",
  prompt: "Write a vegetarian lasagna recipe.",
});
```

### With Messages

```typescript
const { text } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  messages: [
    { role: "user", content: "Hello!" },
    { role: "assistant", content: "Hi! How can I help?" },
    { role: "user", content: "What's the weather?" },
  ],
});
```

### Return Object

| Property           | Description                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------- |
| `text`             | Generated text                                                                              |
| `content`          | Generated content from last step                                                            |
| `finishReason`     | Why generation stopped ('stop', 'length', 'content-filter', 'tool-calls', 'error', 'other') |
| `usage`            | Token usage for final step                                                                  |
| `totalUsage`       | Cumulative usage across all steps                                                           |
| `toolCalls`        | Tool invocations made                                                                       |
| `toolResults`      | Results from tool executions                                                                |
| `response`         | Full response with headers, id, modelId, timestamp                                          |
| `steps`            | Details for all intermediate steps                                                          |
| `reasoning`        | Model reasoning (only some models)                                                          |
| `reasoningText`    | Reasoning as string                                                                         |
| `sources`          | Sources used for generation (RAG models)                                                    |
| `files`            | Generated files                                                                             |
| `output`           | Structured output when using Output specification                                           |
| `providerMetadata` | Provider-specific metadata                                                                  |
| `warnings`         | Provider warnings                                                                           |

## streamText

Real-time streaming for interactive applications.

```typescript
import { streamText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "Write a poem about AI.",
});

for await (const chunk of result.textStream) {
  process.stdout.write(chunk);
}
```

### Stream Properties

| Property              | Description                                                   |
| --------------------- | ------------------------------------------------------------- |
| `textStream`          | Async iterable of text chunks                                 |
| `fullStream`          | Complete event stream (text, tools, reasoning, sources, etc.) |
| `partialOutputStream` | Stream of partial parsed outputs (with Output spec)           |

### Callbacks

```typescript
const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "Hello",
  onChunk: ({ chunk }) => {
    // chunk types: 'text', 'reasoning', 'source', 'tool-call',
    // 'tool-call-streaming-start', 'tool-call-delta', 'tool-result'
    if (chunk.type === "text") {
      console.log("Text:", chunk.text);
    }
  },
  onStepFinish: ({ text, toolCalls, toolResults, usage }) => {
    console.log("Step finished");
  },
  onFinish: ({ text, usage, finishReason, steps }) => {
    console.log("Finished:", text.length, "chars");
  },
  onError: (error) => {
    console.error("Stream error:", error);
  },
});
```

### API Response

```typescript
// app/api/chat/route.ts
export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: anthropic("claude-sonnet-4-5"),
    messages,
  });

  return result.toUIMessageStreamResponse();
}
```

## Structured Output with Output Specification (v6)

> **Important**: In AI SDK v6, `generateObject` and `streamObject` are **deprecated**.
> Use `generateText`/`streamText` with the `output` property instead.

### Output.object() - Typed Object Generation

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

const { output } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.object({
    schema: z.object({
      sentiment: z.enum(["positive", "neutral", "negative"]),
      topics: z.array(z.string()),
      summary: z.string().max(200),
    }),
  }),
  prompt: "Analyze: 'The product is amazing but shipping was slow'",
});

console.log(output.sentiment); // "positive" | "neutral" | "negative"
console.log(output.topics); // string[]
```

### Output.array() - Array Generation

```typescript
import { generateText, Output } from "ai";
import { z } from "zod";

const { output } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.array({
    element: z.object({
      title: z.string(),
      priority: z.number().min(1).max(5),
    }),
  }),
  prompt: "Generate 5 todo items for a web developer",
});

// output is typed as Array<{ title: string; priority: number }>
```

### Output.choice() - Enum/Choice Generation

```typescript
import { generateText, Output } from "ai";

const { output } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.choice({
    options: ["bug", "feature", "question", "documentation"],
  }),
  prompt: "Classify: 'The login button is not working'",
});

// output is typed as "bug" | "feature" | "question" | "documentation"
```

### Output.json() - Unstructured JSON

```typescript
import { generateText, Output } from "ai";

const { output } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.json(),
  prompt: "Return user data as JSON",
});

// output is unknown JSON object
```

### Streaming Structured Output

```typescript
import { streamText, Output } from "ai";
import { z } from "zod";

const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.object({
    schema: z.object({
      recipe: z.object({
        name: z.string(),
        ingredients: z.array(z.string()),
        steps: z.array(z.string()),
      }),
    }),
  }),
  prompt: "Generate a pasta recipe",
});

// Stream partial objects as they're generated
for await (const partial of result.partialOutputStream) {
  console.log("Partial:", partial);
}

// Get final complete output
const { output } = await result;
console.log("Final:", output);
```

### Combined: Tools + Structured Output

AI SDK v6 enables multi-step tool calling with structured output at the end:

```typescript
import { generateText, Output, tool } from "ai";
import { z } from "zod";

const { output, steps } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  tools: {
    getWeather: tool({
      description: "Get weather for a location",
      inputSchema: z.object({ city: z.string() }),
      execute: async ({ city }) => ({ temp: 22, conditions: "sunny" }),
    }),
  },
  output: Output.object({
    schema: z.object({
      recommendation: z.string(),
      confidence: z.number(),
    }),
  }),
  prompt: "Should I bring an umbrella to Helsinki today?",
});

// Tools are called first, then structured output is generated
console.log(output.recommendation);
```

## Legacy: generateObject / streamObject (Deprecated)

> **Deprecation Notice**: These functions will be removed in a future version.
> Migrate to `generateText`/`streamText` with `Output` specification.

```typescript
// DEPRECATED - Don't use in new code
import { generateObject } from "ai";

const { object } = await generateObject({
  model: anthropic("claude-sonnet-4-5"),
  schema: z.object({ ... }),
  prompt: "...",
});

// NEW - Use this instead
import { generateText, Output } from "ai";

const { output } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.object({ schema: z.object({ ... }) }),
  prompt: "...",
});
```

## Common Options

All core functions support these options:

```typescript
{
  model: anthropic("claude-sonnet-4-5"),
  prompt: "...",
  system: "...",
  messages: [...],

  // Generation settings
  temperature: 0.7,
  maxOutputTokens: 1000,
  topP: 0.9,
  topK: 40,
  presencePenalty: 0,
  frequencyPenalty: 0,
  stopSequences: ["END"],
  seed: 12345,

  // Multi-step / Agent settings
  tools: { ... },
  toolChoice: "auto" | "none" | "required" | { type: "tool", toolName: "..." },
  stopWhen: stepCountIs(10),
  prepareStep: ({ steps, stepNumber }) => ({ ... }),

  // Structured output (v6)
  output: Output.object({ schema }) | Output.array({ element }) | Output.choice({ options }),

  // Provider options
  providerOptions: {
    anthropic: { ... },
  },

  // Request control
  abortSignal: controller.signal,
  timeout: 30000,
  maxRetries: 2,
  headers: { ... },
}
```

## Migration: v5 to v6

```bash
# Run automatic migration
npx @ai-sdk/codemod v6
```

Key changes:

- `toDataStreamResponse()` → `toUIMessageStreamResponse()`
- `generateObject()` → `generateText()` with `Output.object()`
- `streamObject()` → `streamText()` with `Output.object()`
- `parameters` in tools → `inputSchema`
