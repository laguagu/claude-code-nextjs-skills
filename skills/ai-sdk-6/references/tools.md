# Tools

## Defining Tools

```typescript
import { tool } from "ai";
import { z } from "zod";

const weatherTool = tool({
  description: "Get the current weather in a location",
  inputSchema: z.object({
    location: z.string().describe("City name"),
    unit: z.enum(["celsius", "fahrenheit"]).optional().default("celsius"),
  }),
  execute: async ({ location, unit }) => {
    // Fetch weather data
    return {
      temperature: 22,
      conditions: "sunny",
      unit,
    };
  },
});
```

## Tool Properties

| Property      | Required | Description                               |
| ------------- | -------- | ----------------------------------------- |
| `description` | No       | Helps model decide when to use tool       |
| `inputSchema` | Yes      | Zod schema for input validation           |
| `execute`     | No       | Async function to run when tool is called |

## Using Tools with generateText

```typescript
import { generateText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const { text, toolCalls, toolResults } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "What's the weather in Tokyo?",
  tools: {
    weather: weatherTool,
  },
});

console.log("Tool calls:", toolCalls);
console.log("Tool results:", toolResults);
```

## Using Tools with streamText

```typescript
import { streamText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "What's the weather in Tokyo?",
  tools: {
    weather: weatherTool,
  },
});

for await (const event of result.fullStream) {
  switch (event.type) {
    case "tool-call":
      console.log("Tool called:", event.toolName, event.args);
      break;
    case "tool-result":
      console.log("Tool result:", event.result);
      break;
    case "text-delta":
      process.stdout.write(event.textDelta);
      break;
  }
}
```

## Tool Choice

Control how the model uses tools:

```typescript
// Let model decide (default)
{ toolChoice: "auto" }

// Force tool use
{ toolChoice: "required" }

// Disable tools
{ toolChoice: "none" }

// Force specific tool
{
  toolChoice: {
    type: "tool",
    toolName: "weather",
  }
}
```

## Tools Without Execute

For client-side tool handling:

```typescript
const confirmTool = tool({
  description: "Request user confirmation",
  inputSchema: z.object({
    message: z.string(),
  }),
  // No execute - handled by client
});

const { toolCalls } = await generateText({
  model: anthropic("claude-sonnet-4-5"),
  prompt: "Delete all files?",
  tools: { confirm: confirmTool },
});

// Handle tool calls client-side
for (const call of toolCalls) {
  if (call.toolName === "confirm") {
    const confirmed = await showConfirmDialog(call.args.message);
    // Continue with confirmation result
  }
}
```

## Complex Tool Schemas

```typescript
const createTaskTool = tool({
  description: "Create a new task",
  inputSchema: z.object({
    title: z.string().min(1).max(100),
    description: z.string().optional(),
    priority: z.enum(["low", "medium", "high"]),
    dueDate: z.string().datetime().optional(),
    tags: z.array(z.string()).max(5).optional(),
    assignee: z
      .object({
        id: z.string(),
        name: z.string(),
      })
      .optional(),
  }),
  execute: async (task) => {
    const created = await db.tasks.create(task);
    return { id: created.id, status: "created" };
  },
});
```

## Multiple Tools

```typescript
import { ToolLoopAgent } from "ai";

const agent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  tools: {
    search: tool({
      description: "Search the web",
      inputSchema: z.object({ query: z.string() }),
      execute: async ({ query }) => searchWeb(query),
    }),
    calculate: tool({
      description: "Perform calculations",
      inputSchema: z.object({ expression: z.string() }),
      execute: async ({ expression }) => {
        const { evaluate } = await import("mathjs");
        return evaluate(expression);
      },
    }),
    weather: tool({
      description: "Get weather data",
      inputSchema: z.object({ location: z.string() }),
      execute: async ({ location }) => getWeather(location),
    }),
  },
});
```

## Schema Libraries

### Zod (Recommended)

```typescript
import { z } from "zod";

const schema = z.object({
  name: z.string(),
  age: z.number().int().positive(),
});
```

### Valibot

```typescript
import { valibotSchema } from "@ai-sdk/valibot";
import * as v from "valibot";

const schema = valibotSchema(
  v.object({
    name: v.string(),
    age: v.number(),
  }),
);
```

### JSON Schema

```typescript
import { jsonSchema } from "ai";

const schema = jsonSchema({
  type: "object",
  properties: {
    name: { type: "string" },
    age: { type: "integer" },
  },
  required: ["name", "age"],
});
```

## Typed Tool Results

```typescript
const weatherTool = tool({
  description: "Get weather",
  inputSchema: z.object({
    location: z.string(),
  }),
  outputSchema: z.object({
    temperature: z.number(),
    conditions: z.string(),
  }),
  execute: async ({ location }) => {
    return {
      temperature: 22,
      conditions: "sunny",
    };
  },
});
```
