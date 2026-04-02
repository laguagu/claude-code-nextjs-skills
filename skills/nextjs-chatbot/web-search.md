# Web Search Tool Patterns

Add real-time web content to chatbots when the knowledge base alone isn't enough (events, news, dynamic content).

For all provider-specific approaches (OpenAI, Google, Perplexity, Exa, Tavily, Firecrawl), see the [AI SDK Web Search Cookbook](https://ai-sdk.dev/cookbook/node/web-search-agent).

## Key principle: domain whitelisting

**Never let the chatbot search the entire web.** Domain-scoped chatbots should only access their own domains:

- **Provider-native** (OpenAI `webSearch()`): use `filters.allowedDomains`
- **Custom tools**: scope the API URL to a single domain — inherently restricted
- **System prompt**: explicitly instruct which tool to use for which question type

Without domain restriction, the LLM will use web search to answer off-topic questions, bypassing scope enforcement.

## Custom fetch tool

When using Azure OpenAI (no native `webSearch()`) or targeting a specific site with a known API:

```ts
import { tool } from "ai";
import { z } from "zod";

const cache = new Map<string, { data: unknown; ts: number }>();
const CACHE_TTL = 60 * 60 * 1000; // 1 hour

export const searchWebsiteTool = tool({
  description: "Search the project website for events, news, and announcements.",
  inputSchema: z.object({
    query: z.string().describe("Search query"),
  }),
  execute: async ({ query }) => {
    const cacheKey = query.toLowerCase().trim();
    const cached = cache.get(cacheKey);
    if (cached && Date.now() - cached.ts < CACHE_TTL) return cached.data;

    const res = await fetch(`${API_BASE}/search?q=${encodeURIComponent(query)}&limit=5`, {
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return { results: [], total: 0 };

    const results = await res.json();
    const data = { results, total: results.length };
    cache.set(cacheKey, { data, ts: Date.now() });
    return data;
  },
});
```

Key rules:

- **Always cache** — external APIs can be slow; 1h TTL prevents hammering
- **AbortSignal.timeout** — prevent hanging requests from blocking the agent
- **Scope to one domain** — the tool description should make clear what it searches
- **Strip HTML** if the API returns rendered content (title, excerpt)

## Tool priority in system prompt

When web search coexists with domain-specific tools, enforce priority:

```
## Tool Priority
- For domain-specific questions: use dedicated tools first
- For events, news, workshops, current content: searchWebsite
- Do NOT use searchWebsite for questions answerable by domain tools
```

## Checklist

- [ ] Choose approach based on provider ([AI SDK cookbook](https://ai-sdk.dev/cookbook/node/web-search-agent) for options)
- [ ] Add domain whitelisting or inherent scope restriction
- [ ] Implement caching (TTL cache for custom tools)
- [ ] Add loading shimmer: "Searching..."
- [ ] Add UI renderer for results
- [ ] Update agent instructions with tool priority rules
