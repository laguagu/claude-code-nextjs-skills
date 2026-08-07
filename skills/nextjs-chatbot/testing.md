# Testing a chatbot

Two instruments that answer different questions. `createChat` tests **the UI
given a response**; benchmarks test **whether the model produces that response**.
Neither replaces the other.

## Contents

- Building chat UI without a model (`@shadcn/helpers/ai-sdk`)
- Evals / benchmarks: fixture schema, assertion fields, stability
- What to skip when the chatbot is open-ended Q&A

## Building chat UI without a model

`@shadcn/helpers/ai-sdk` runs a scripted conversation through the **real `useChat` lifecycle** — no model, API route, network request, or API key. Every part type streams the way it would in production.

```bash
bun add @shadcn/helpers
```

```tsx
import { useChat } from "@ai-sdk/react";
import { createChat } from "@shadcn/helpers/ai-sdk";

const chat = createChat()
  .user("Which components parse PDFs?")
  .assistant((w) => {
    w.reasoning("Catalog question — search first.");
    w.tool("searchComponents", { input: { tags: ["pdf"] }, output: fixtures.pdf });
    w.text("Two options: …");
  });

export function ChatDemo() {
  const { messages, sendMessage } = useChat({
    messages: chat.get(0),
    transport: chat.transport(),
  });
  const next = chat.next(messages);
  return <button onClick={() => next && sendMessage(next)}>Next</button>;
}
```

Writers inside `.assistant()`: `text()`, `reasoning()`, `tool()`, `data()`, `file()`, `sourceUrl()`, `sourceDocument()`, `stepStart()`, `custom()`.

Use it for:

- **Tool-render states** — drive a tool part through `input-streaming` → `input-available` → `output-available` → `error` deterministically instead of waiting for a live model to reproduce each one. Same for the 5-state HITL machine (see [hitl.md](hitl.md)).
- **Streaming-flicker regressions** — the multi-tool `isGenerating` bug (SKILL.md, "Message streaming state") reproduces reliably here.
- **Docs, demos, screenshots** — a fixed conversation that never drifts or costs tokens.


## Evals / Benchmarks

Single-run `pass/fail` suites catch tool-accuracy and scope regressions but miss two failure modes that only surface under repetition: **instability** (same prompt, different result set across runs) and **hallucination** (LLM invents names not in any tool result). Add fixtures for both when the chatbot serves a bounded catalog.

### Fixture schema

```jsonc
{
  "tests": [
    {
      "id": "agent-001",
      "description": "User asks about PDF parsing",
      "input": { "prompt": "What component parses PDFs?" },
      "expected": {
        "requiredTools": ["searchComponents"],
        "responseContains": ["Parser"],
        "responseNotContains": ["FooBarParser", "pkg[foo-bar]"]
      }
    },
    {
      "id": "stability-rag-browse",
      "description": "Same catalog question → same result set across runs",
      "input": { "prompt": "What RAG components are available?" },
      "runs": 5,
      "stabilityThreshold": 0.8,
      "expected": {
        "requiredTools": ["searchComponents"],
        "resultMustContain": ["Retriever", "Embedder", "VectorStore", "AnswerGenerator"],
        "minResultCount": 4,
        "toolParams": [
          { "tool": "searchComponents", "mustInclude": { "tags": ["rag"] }, "mustNotInclude": ["freeText"] }
        ]
      }
    }
  ]
}
```

### Extra assertion fields

- `runs: N` (default 1) — evaluator runs the prompt N times and records tool calls + results each time
- `stabilityThreshold: 0–1` — test fails if `|intersection| / |union|` over tool-result identifier sets across runs is below this
- `toolParams: [{ tool, mustInclude?, mustNotInclude? }]` — asserts the agent actually passed the expected filter shape (not just called the tool)
- `resultMustContain: string[]` — names that must appear in aggregated tool results (proves retrieval quality, not just prose)
- `minResultCount` / `maxResultCount` — guardrails for result-set size
- `responseNotContains` — hallucination guard: list known-fake names the LLM tends to invent so a regression fails immediately

One production incident: "What X are available?" returned 11 % stability (different 4–6 items across 5 runs) because the tool accepted a freeform `query` and silent SQL retries simplified it each run. Structured tag filters took it to 100 %. Skip stability fixtures if your chatbot doesn't serve a bounded catalog — they're overhead for open-ended Q&A.

Run with `bun run benchmarks/run.ts`. Evaluator runs N times, records tool inputs + outputs, computes pass/fail + stability score.

