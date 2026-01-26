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

| Property        | Required | Description                                      |
| --------------- | -------- | ------------------------------------------------ |
| `description`   | No       | Helps model decide when to use tool              |
| `inputSchema`   | Yes      | Zod schema for input validation                  |
| `outputSchema`  | No       | Zod schema for output type safety                |
| `execute`       | No       | Async function to run when tool is called        |
| `needsApproval` | No       | Require user approval before execution (boolean or function) |

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

## Tool Execution Approval

Require user confirmation before server-side tools execute:

### Basic Approval

```typescript
const deleteFileTool = tool({
  description: "Delete a file from the system",
  inputSchema: z.object({
    filename: z.string(),
  }),
  needsApproval: true, // Always require approval
  execute: async ({ filename }) => {
    await fs.unlink(filename);
    return { deleted: true };
  },
});
```

### Dynamic Approval

```typescript
const transferTool = tool({
  description: "Transfer funds",
  inputSchema: z.object({
    amount: z.number(),
    to: z.string(),
  }),
  // Only require approval for large amounts
  needsApproval: ({ amount }) => amount > 1000,
  execute: async ({ amount, to }) => {
    return await transferFunds(amount, to);
  },
});
```

### Client-Side Approval Handling

See [ui-hooks.md](ui-hooks.md#tool-approval-needsapproval) for client-side approval UI.

## Client-Side Tools (No execute)

For tools that run in the browser:

```typescript
const confirmTool = tool({
  description: "Request user confirmation",
  inputSchema: z.object({
    message: z.string(),
  }),
  // No execute - handled by client via onToolCall
});

const getLocationTool = tool({
  description: "Get user's current location",
  inputSchema: z.object({}),
  // No execute - handled by client
});
```

## Tool Part States

When rendering tool calls in the UI, handle these states:

| State              | Description                                    |
| ------------------ | ---------------------------------------------- |
| `input-streaming`  | Tool input is being streamed (partial args)    |
| `input-available`  | Tool input is complete, awaiting execution     |
| `approval-requested` | Awaiting user approval (needsApproval: true) |
| `output-available` | Tool execution completed successfully          |
| `output-error`     | Tool execution failed                          |

```typescript
{message.parts.map((part) => {
  if (part.type === "tool-weather") {
    switch (part.state) {
      case "input-streaming":
        return <div>Preparing request...</div>;
      case "input-available":
        return <div>Getting weather for {part.input.location}...</div>;
      case "approval-requested":
        return <ApprovalDialog part={part} />;
      case "output-available":
        return <WeatherCard data={part.output} />;
      case "output-error":
        return <div>Error: {part.errorText}</div>;
    }
  }
})}
```

## Dynamic Tools

Tools with unknown schemas at compile time use the `dynamic-tool` type:

```typescript
// Server-side: Tools loaded at runtime (e.g., from MCP)
const dynamicTools = await loadMCPTools();

const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  tools: dynamicTools,
  // ...
});

// Client-side: Handle dynamic-tool type
{message.parts.map((part) => {
  if (part.type === "dynamic-tool") {
    return (
      <div key={part.toolCallId}>
        <h4>Tool: {part.toolName}</h4>
        {part.state === "input-streaming" && (
          <pre>{JSON.stringify(part.input, null, 2)}</pre>
        )}
        {part.state === "output-available" && (
          <pre>{JSON.stringify(part.output, null, 2)}</pre>
        )}
        {part.state === "output-error" && (
          <div>Error: {part.errorText}</div>
        )}
      </div>
    );
  }
})}
```

### Dynamic Tool Check in onToolCall

```typescript
async onToolCall({ toolCall }) {
  // IMPORTANT: Check dynamic first for TypeScript type narrowing
  if (toolCall.dynamic) {
    // Handle unknown tools
    console.log("Dynamic tool:", toolCall.toolName, toolCall.args);
    return;
  }

  // TypeScript now knows this is a static tool
  if (toolCall.toolName === "getLocation") {
    addToolOutput({
      tool: "getLocation",
      toolCallId: toolCall.toolCallId,
      output: "Helsinki",
    });
  }
},
```

## Tool Call Streaming

Tool call streaming is **enabled by default** in AI SDK v6:

```typescript
// Tool inputs stream as they're generated
{message.parts.map((part) => {
  if (part.type === "tool-search") {
    if (part.state === "input-streaming") {
      // Show partial input as it streams
      return <pre>{JSON.stringify(part.input, null, 2)}</pre>;
    }
    if (part.state === "input-available") {
      return <div>Searching for: {part.input.query}</div>;
    }
  }
})}
```

## Multi-Step Tool Calls

### Server-Side Multi-Step

```typescript
import { streamText, stepCountIs } from "ai";

const result = streamText({
  model: anthropic("claude-sonnet-4-5"),
  messages: await convertToModelMessages(messages),
  tools: {
    search: searchTool,
    calculate: calculateTool,
  },
  stopWhen: stepCountIs(5), // Max 5 tool call iterations
});

return result.toUIMessageStreamResponse();
```

### Step Boundaries in UI

```typescript
{message.parts.map((part, index) => {
  switch (part.type) {
    case "step-start":
      // Show step boundaries as horizontal lines
      return index > 0 ? <hr key={index} /> : null;
    case "text":
      return <p key={index}>{part.text}</p>;
    case "tool-search":
    case "tool-calculate":
      return <ToolDisplay key={index} part={part} />;
  }
})}
```

### Client-Side Auto-Submit

```typescript
import { lastAssistantMessageIsCompleteWithToolCalls } from "ai";

const { messages, sendMessage, addToolOutput } = useChat({
  transport: new DefaultChatTransport({ api: "/api/chat" }),

  // Auto-resubmit when all tool results available
  sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithToolCalls,

  async onToolCall({ toolCall }) {
    if (toolCall.dynamic) return;
    // Provide tool result...
  },
});
```

## Error Handling

### Client-Side Tool Errors

```typescript
async onToolCall({ toolCall }) {
  if (toolCall.dynamic) return;

  if (toolCall.toolName === "fetchData") {
    try {
      const data = await fetchData(toolCall.input);
      addToolOutput({
        tool: "fetchData",
        toolCallId: toolCall.toolCallId,
        output: data,
      });
    } catch (err) {
      // Report error state
      addToolOutput({
        tool: "fetchData",
        toolCallId: toolCall.toolCallId,
        state: "output-error",
        errorText: err instanceof Error ? err.message : "Unknown error",
      });
    }
  }
},
```

### Server-Side Error Handling

```typescript
return result.toUIMessageStreamResponse({
  onError: (error) => {
    if (error == null) return "Unknown error";
    if (typeof error === "string") return error;
    if (error instanceof Error) return error.message;
    return JSON.stringify(error);
  },
});
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

## Multiple Tools with Agent

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

## Type Inference

```typescript
import { InferUITool, InferUITools, ToolSet } from "ai";

// Single tool
type WeatherUITool = InferUITool<typeof weatherTool>;
// { input: { location: string }; output: { temperature: number; conditions: string } }

// Tool set
const tools = {
  weather: weatherTool,
  search: searchTool,
} satisfies ToolSet;

type MyUITools = InferUITools<typeof tools>;
// { weather: { input: ...; output: ... }; search: { input: ...; output: ... } }
```
