# Agents in AI SDK v6

## ToolLoopAgent Class

The `ToolLoopAgent` class encapsulates LLM configuration, tools, and behavior into reusable components.

### Creating an Agent

```typescript
import { ToolLoopAgent, tool, stepCountIs } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

const codeAgent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  instructions: `You are a senior software engineer.
    Focus on security, performance, and maintainability.`,
  tools: {
    runCode: tool({
      description: "Execute Python code",
      inputSchema: z.object({
        code: z.string(),
      }),
      execute: async ({ code }) => {
        return { output: "Code executed successfully" };
      },
    }),
  },
  stopWhen: stepCountIs(20),
});
```

### Configuration Options

| Option              | Description                                    |
| ------------------- | ---------------------------------------------- |
| `model`             | AI model to use                                |
| `instructions`      | System prompt defining agent behavior          |
| `tools`             | Tools the agent can use                        |
| `stopWhen`          | Stopping conditions (default: 20 steps)        |
| `toolChoice`        | Control tool usage: `auto`, `required`, `none` |
| `output`            | Structured output schema                       |
| `prepareStep`       | Callback to modify settings per step           |
| `callOptionsSchema` | Type-safe call options schema                  |

### Using the Agent

```typescript
// Non-streaming
const { text, toolCalls } = await myAgent.generate({
  prompt: "Analyze this data",
});

// Streaming
const stream = myAgent.stream({
  prompt: "Tell me a story",
});

for await (const chunk of stream.textStream) {
  console.log(chunk);
}
```

### API Route Integration

```typescript
// app/api/chat/route.ts
import { createAgentUIStreamResponse } from "ai";
import { myAgent } from "@/agents/my-agent";

export async function POST(request: Request) {
  const { messages } = await request.json();

  return createAgentUIStreamResponse({
    agent: myAgent,
    uiMessages: messages,
    sendSources: true,
    includeUsage: true,
  });
}
```

## Loop Control

### Stop Conditions

```typescript
import { ToolLoopAgent, stepCountIs, hasToolCall } from "ai";

const agent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  tools: {
    /* ... */
  },
  stopWhen: [
    stepCountIs(20), // Max 20 steps
    hasToolCall("finalize"), // Stop after specific tool
  ],
});
```

### Custom Stop Conditions

```typescript
import { StopCondition, ToolSet } from "ai";

const tools = {
  /* ... */
} satisfies ToolSet;

const hasAnswer: StopCondition<typeof tools> = ({ steps }) => {
  return steps.some((step) => step.text?.includes("ANSWER:")) ?? false;
};

const budgetExceeded: StopCondition<typeof tools> = ({ steps }) => {
  const totalUsage = steps.reduce(
    (acc, step) => ({
      inputTokens: acc.inputTokens + (step.usage?.inputTokens ?? 0),
      outputTokens: acc.outputTokens + (step.usage?.outputTokens ?? 0),
    }),
    { inputTokens: 0, outputTokens: 0 },
  );
  const cost =
    (totalUsage.inputTokens * 0.01 + totalUsage.outputTokens * 0.03) / 1000;
  return cost > 0.5;
};
```

### prepareStep - Dynamic Configuration

```typescript
const agent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  tools: {
    search: searchTool,
    analyze: analyzeTool,
    summarize: summarizeTool,
  },
  prepareStep: async ({ stepNumber, messages }) => {
    // Search phase (steps 0-2)
    if (stepNumber <= 2) {
      return {
        activeTools: ["search"],
        toolChoice: "required",
      };
    }
    // Analysis phase (steps 3-5)
    if (stepNumber <= 5) {
      return { activeTools: ["analyze"] };
    }
    // Summary phase
    return {
      activeTools: ["summarize"],
      toolChoice: "required",
    };
  },
});
```

### Context Management

```typescript
prepareStep: async ({ messages }) => {
  if (messages.length > 20) {
    return {
      messages: [
        messages[0],         // Keep system instructions
        ...messages.slice(-10), // Keep last 10 messages
      ],
    };
  }
  return {};
},
```

## Call Options

Type-safe runtime configuration:

```typescript
const supportAgent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  callOptionsSchema: z.object({
    userId: z.string(),
    accountType: z.enum(["free", "pro", "enterprise"]),
  }),
  instructions: "You are a customer support agent.",
  prepareCall: ({ options, ...settings }) => ({
    ...settings,
    instructions:
      settings.instructions +
      `
      User context:
      - Account: ${options.accountType}
      - User ID: ${options.userId}
    `,
  }),
});

const result = await supportAgent.generate({
  prompt: "How do I upgrade?",
  options: {
    userId: "user_123",
    accountType: "free",
  },
});
```

### Async prepareCall with RAG

`prepareCall` can be async for fetching context:

```typescript
const ragAgent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  callOptionsSchema: z.object({
    query: z.string(),
    complexity: z.enum(["simple", "complex"]).optional(),
  }),
  prepareCall: async ({ options, ...settings }) => {
    // Fetch relevant documents (async)
    const documents = await vectorSearch(options.query);

    return {
      ...settings,
      // Dynamic model selection
      model:
        options.complexity === "complex"
          ? anthropic("claude-sonnet-4-5")
          : anthropic("claude-haiku-3-5-20250929"),
      // Inject context into instructions
      instructions: `Answer using this context:

${documents.map((doc) => doc.content).join("\n\n")}`,
    };
  },
});
```

## Structured Output

```typescript
import { Output } from "ai";

const analysisAgent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  output: Output.object({
    schema: z.object({
      sentiment: z.enum(["positive", "neutral", "negative"]),
      summary: z.string(),
      keyPoints: z.array(z.string()),
    }),
  }),
  stopWhen: stepCountIs(10),
});

const { output } = await analysisAgent.generate({
  prompt: "Analyze customer feedback",
});

console.log(output.sentiment); // Type-safe access
```

## Type-Safe UIMessage

```typescript
import { ToolLoopAgent, InferAgentUIMessage } from "ai";

const myAgent = new ToolLoopAgent({
  /* config */
});

export type MyAgentUIMessage = InferAgentUIMessage<typeof myAgent>;
```

Use in client:

```typescript
"use client";
import { useChat } from "@ai-sdk/react";
import type { MyAgentUIMessage } from "@/agents/my-agent";

export function Chat() {
  const { messages } = useChat<MyAgentUIMessage>();
  // Full type safety for messages and tools
}
```
