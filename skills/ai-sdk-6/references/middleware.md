# Middleware

Language model middleware for intercepting and modifying model behavior.

## Core Interception Points

| Hook              | Purpose                             |
| ----------------- | ----------------------------------- |
| `transformParams` | Modify parameters before model call |
| `wrapGenerate`    | Wrap non-streaming calls            |
| `wrapStream`      | Wrap streaming calls                |

## Built-in Middleware

### Extract Reasoning

```typescript
import { wrapLanguageModel, extractReasoningMiddleware } from "ai";

const model = wrapLanguageModel({
  model: anthropic("claude-sonnet-4-5"),
  middleware: extractReasoningMiddleware({ tagName: "think" }),
});
```

### Simulate Streaming

```typescript
import { wrapLanguageModel, simulateStreamingMiddleware } from "ai";

const model = wrapLanguageModel({
  model: yourModel,
  middleware: simulateStreamingMiddleware(),
});
```

### Default Settings

```typescript
import { wrapLanguageModel, defaultSettingsMiddleware } from "ai";

const model = wrapLanguageModel({
  model: anthropic("claude-sonnet-4-5"),
  middleware: defaultSettingsMiddleware({
    settings: {
      temperature: 0.5,
      maxOutputTokens: 800,
    },
  }),
});
```

## Multiple Middleware

Stack in application order:

```typescript
const wrappedModel = wrapLanguageModel({
  model: yourModel,
  middleware: [firstMiddleware, secondMiddleware],
  // Applied as: firstMiddleware(secondMiddleware(yourModel))
});
```

## Custom Middleware

### Logging

```typescript
import { LanguageModelV3Middleware } from "ai";

export const logMiddleware: LanguageModelV3Middleware = {
  wrapGenerate: async ({ doGenerate, params }) => {
    console.log("Parameters:", JSON.stringify(params, null, 2));
    const result = await doGenerate();
    console.log("Generated:", result.text);
    return result;
  },
  wrapStream: async ({ doStream, params }) => {
    const { stream, ...rest } = await doStream();
    const transformStream = new TransformStream({
      transform(chunk, controller) {
        console.log("Chunk:", chunk);
        controller.enqueue(chunk);
      },
    });
    return { stream: stream.pipeThrough(transformStream), ...rest };
  },
};
```

### Caching

```typescript
const cache = new Map<string, any>();

export const cacheMiddleware: LanguageModelV3Middleware = {
  wrapGenerate: async ({ doGenerate, params }) => {
    const key = JSON.stringify(params);
    if (cache.has(key)) {
      return cache.get(key);
    }
    const result = await doGenerate();
    cache.set(key, result);
    return result;
  },
};
```

### RAG (Retrieval-Augmented Generation)

```typescript
export const ragMiddleware: LanguageModelV3Middleware = {
  transformParams: async ({ params }) => {
    const messageText = getLastUserMessageText({ prompt: params.prompt });
    if (!messageText) return params;

    const sources = await vectorSearch(messageText);
    const contextInstruction = sources
      .map((chunk) => JSON.stringify(chunk))
      .join("\n");

    return addToLastUserMessage({ params, text: contextInstruction });
  },
};
```

### Guardrails

```typescript
export const guardrailMiddleware: LanguageModelV3Middleware = {
  wrapGenerate: async ({ doGenerate }) => {
    const { text, ...rest } = await doGenerate();
    const cleaned = text?.replace(/badword/g, "<REDACTED>");
    return { text: cleaned, ...rest };
  },
};
```

## Per-Request Metadata

Pass context through `providerOptions`:

```typescript
const { text } = await generateText({
  model: wrapLanguageModel({
    model: anthropic("claude-sonnet-4-5"),
    middleware: customMiddleware,
  }),
  prompt: "Your prompt...",
  providerOptions: {
    customMiddleware: {
      userId: "123",
      timestamp: Date.now(),
    },
  },
});
```

Access in middleware:

```typescript
wrapGenerate: async ({ doGenerate, params }) => {
  const metadata = params?.providerMetadata?.customMiddleware;
  console.log("User:", metadata?.userId);
  return doGenerate();
};
```

## Best Practices

1. **Order matters** - Stack logically (logging before caching)
2. **Handle streams carefully** - Buffering may be needed for guardrails
3. **Reuse middleware** - Share across model instances
4. **Type safety** - Implement proper TypeScript interfaces
5. **Error handling** - Prevent cascade failures
