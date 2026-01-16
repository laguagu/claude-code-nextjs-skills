# MCP (Model Context Protocol) Integration

Connect to MCP servers to access external tools, resources, and prompts.

## Installation

```bash
bun add @ai-sdk/mcp
```

## Transport Types

### HTTP Transport (Production)

```typescript
import { createMCPClient } from "@ai-sdk/mcp";

const mcpClient = await createMCPClient({
  transport: {
    type: "http",
    url: "https://your-server.com/mcp",
    headers: { Authorization: "Bearer my-api-key" },
  },
});
```

### SSE Transport

```typescript
const mcpClient = await createMCPClient({
  transport: {
    type: "sse",
    url: "https://my-server.com/sse",
    headers: { Authorization: "Bearer my-api-key" },
  },
});
```

### Stdio Transport (Local Development)

```typescript
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const mcpClient = await createMCPClient({
  transport: new StdioClientTransport({
    command: "node",
    args: ["src/server.js"],
  }),
});
```

## Tool Discovery

### Auto-discovery

```typescript
const tools = await mcpClient.tools();
```

### Type-safe Schema Definition

```typescript
import { z } from "zod";

const tools = await mcpClient.tools({
  schemas: {
    "get-weather": {
      inputSchema: z.object({
        location: z.string().describe("City name"),
      }),
      outputSchema: z.object({
        temperature: z.number(),
        conditions: z.string(),
      }),
    },
  },
});
```

## Full Integration Example

```typescript
import { createMCPClient } from "@ai-sdk/mcp";
import { streamText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

const mcpClient = await createMCPClient({
  transport: {
    type: "http",
    url: "https://your-server.com/mcp",
    headers: { Authorization: "Bearer my-api-key" },
  },
});

const tools = await mcpClient.tools({
  schemas: {
    "get-weather": {
      inputSchema: z.object({ location: z.string() }),
      outputSchema: z.object({
        temperature: z.number(),
        conditions: z.string(),
      }),
    },
  },
});

const result = await streamText({
  model: anthropic("claude-sonnet-4-5"),
  tools,
  prompt: "What is the weather in Brooklyn?",
  onFinish: async () => {
    await mcpClient.close();
  },
});
```

## Multiple MCP Clients

```typescript
const weatherClient = await createMCPClient({
  transport: { type: "http", url: "https://weather-server.com/mcp" },
});

const dataClient = await createMCPClient({
  transport: { type: "http", url: "https://data-server.com/mcp" },
});

const combinedTools = {
  ...(await weatherClient.tools()),
  ...(await dataClient.tools()),
};

try {
  await streamText({
    model: anthropic("claude-sonnet-4-5"),
    tools: combinedTools,
    prompt: "Fetch and analyze data",
  });
} finally {
  await weatherClient.close();
  await dataClient.close();
}
```

## Additional Features

| Method                                   | Description              |
| ---------------------------------------- | ------------------------ |
| `mcpClient.listResources()`              | List available resources |
| `mcpClient.readResource(uri)`            | Read a specific resource |
| `mcpClient.listResourceTemplates()`      | List resource templates  |
| `mcpClient.experimental_listPrompts()`   | List available prompts   |
| `mcpClient.experimental_getPrompt(name)` | Get a specific prompt    |

## Elicitation Support

For interactive tool flows requiring user input:

```typescript
const mcpClient = await createMCPClient({
  transport: {
    type: "sse",
    url: "https://your-server.com/sse",
  },
  capabilities: {
    elicitation: {},
  },
});

mcpClient.onElicitationRequest(ElicitationRequestSchema, async (request) => {
  try {
    const userInput = await getInputFromUser(
      request.params.message,
      request.params.requestedSchema,
    );
    return {
      action: "accept",
      content: userInput,
    };
  } catch (error) {
    return { action: "decline" };
  }
});
```

## Error Handling

```typescript
let mcpClient: MCPClient | undefined;

try {
  mcpClient = await createMCPClient({
    transport: {
      type: "http",
      url: "https://your-server.com/mcp",
    },
  });

  const tools = await mcpClient.tools();
  await streamText({
    model: anthropic("claude-sonnet-4-5"),
    tools,
    prompt: "Your prompt here",
  });
} catch (error) {
  console.error("MCP Client Error:", error);
} finally {
  await mcpClient?.close();
}
```

## Best Practices

1. **Always close the client** - Use `onFinish` or `try/finally`
2. **HTTP/SSE for production** - Stdio only for local dev
3. **Define schemas explicitly** - Better TypeScript integration
4. **Handle errors gracefully** - MCP servers may be unavailable
5. **Use OAuth when available** - Pass `authProvider` for auto-auth
