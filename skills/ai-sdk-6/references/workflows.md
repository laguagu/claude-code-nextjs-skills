# Workflow Patterns

Structured patterns for building reliable AI workflows.

## Pattern Overview

| Pattern             | Use Case                         |
| ------------------- | -------------------------------- |
| Sequential (Chains) | Steps in predefined order        |
| Parallel            | Independent tasks simultaneously |
| Routing             | Context-based path selection     |
| Orchestrator-Worker | Coordinated specialized workers  |
| Evaluator-Optimizer | Quality control with iteration   |

## Sequential Processing

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

async function generateMarketingCopy(input: string) {
  const model = anthropic("claude-sonnet-4-5");

  // Step 1: Generate copy
  const { text: copy } = await generateText({
    model,
    prompt: `Write persuasive marketing copy for: ${input}`,
  });

  // Step 2: Quality check
  const { output: quality } = await generateText({
    model,
    output: Output.object({
      schema: z.object({
        hasCallToAction: z.boolean(),
        emotionalAppeal: z.number().min(1).max(10),
        clarity: z.number().min(1).max(10),
      }),
    }),
    prompt: `Evaluate this marketing copy: ${copy}`,
  });

  // Step 3: Improve if needed
  if (!quality.hasCallToAction || quality.emotionalAppeal < 7) {
    const { text: improved } = await generateText({
      model,
      prompt: `Improve this copy with better CTA and emotion: ${copy}`,
    });
    return { copy: improved, quality };
  }

  return { copy, quality };
}
```

## Routing

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";

async function handleCustomerQuery(query: string) {
  const model = anthropic("claude-sonnet-4-5");

  // Classify the query
  const { output: classification } = await generateText({
    model,
    output: Output.object({
      schema: z.object({
        type: z.enum(["general", "refund", "technical"]),
        complexity: z.enum(["simple", "complex"]),
      }),
    }),
    prompt: `Classify this query: ${query}`,
  });

  // Route based on classification
  const { text: response } = await generateText({
    model:
      classification.complexity === "simple"
        ? openai("gpt-4o-mini")
        : openai("o3-mini"),
    system: {
      general: "You handle general inquiries.",
      refund: "You specialize in refund requests.",
      technical: "You are a technical support specialist.",
    }[classification.type],
    prompt: query,
  });

  return { response, classification };
}
```

## Parallel Processing

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

async function parallelCodeReview(code: string) {
  const model = anthropic("claude-sonnet-4-5");

  // Run reviews in parallel
  const [security, performance, maintainability] = await Promise.all([
    generateText({
      model,
      system: "You are a security expert.",
      output: Output.object({
        schema: z.object({
          vulnerabilities: z.array(z.string()),
          riskLevel: z.enum(["low", "medium", "high"]),
        }),
      }),
      prompt: `Review this code for security: ${code}`,
    }),
    generateText({
      model,
      system: "You are a performance expert.",
      output: Output.object({
        schema: z.object({
          issues: z.array(z.string()),
          optimizations: z.array(z.string()),
        }),
      }),
      prompt: `Review this code for performance: ${code}`,
    }),
    generateText({
      model,
      system: "You are a code quality expert.",
      output: Output.object({
        schema: z.object({
          concerns: z.array(z.string()),
          qualityScore: z.number().min(1).max(10),
        }),
      }),
      prompt: `Review this code for quality: ${code}`,
    }),
  ]);

  // Aggregate results
  const { text: summary } = await generateText({
    model,
    system: "You are a tech lead summarizing reviews.",
    prompt: `Synthesize these reviews: ${JSON.stringify({
      security: security.output,
      performance: performance.output,
      maintainability: maintainability.output,
    })}`,
  });

  return { reviews: { security, performance, maintainability }, summary };
}
```

## Orchestrator-Worker

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

async function implementFeature(request: string) {
  // Orchestrator: Plan the implementation
  const { output: plan } = await generateText({
    model: anthropic("claude-sonnet-4-5"),
    output: Output.object({
      schema: z.object({
        files: z.array(
          z.object({
            purpose: z.string(),
            filePath: z.string(),
            changeType: z.enum(["create", "modify", "delete"]),
          }),
        ),
      }),
    }),
    system: "You are a software architect.",
    prompt: `Plan implementation for: ${request}`,
  });

  // Workers: Execute changes in parallel
  const changes = await Promise.all(
    plan.files.map(async (file) => {
      const { output: change } = await generateText({
        model: anthropic("claude-sonnet-4-5"),
        output: Output.object({
          schema: z.object({
            explanation: z.string(),
            code: z.string(),
          }),
        }),
        system: {
          create: "You implement new files.",
          modify: "You modify existing code safely.",
          delete: "You safely remove code.",
        }[file.changeType],
        prompt: `Implement ${file.filePath}: ${file.purpose}`,
      });

      return { file, implementation: change };
    }),
  );

  return { plan, changes };
}
```

## Evaluator-Optimizer

```typescript
import { generateText, Output } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { z } from "zod";

async function translateWithFeedback(text: string, targetLanguage: string) {
  const model = anthropic("claude-sonnet-4-5");
  let currentTranslation = "";
  let iterations = 0;
  const MAX_ITERATIONS = 3;

  // Initial translation
  const { text: translation } = await generateText({
    model,
    system: "You are an expert translator.",
    prompt: `Translate to ${targetLanguage}: ${text}`,
  });

  currentTranslation = translation;

  // Evaluation-optimization loop
  while (iterations < MAX_ITERATIONS) {
    // Evaluate
    const { output: evaluation } = await generateText({
      model,
      output: Output.object({
        schema: z.object({
          qualityScore: z.number().min(1).max(10),
          preservesTone: z.boolean(),
          issues: z.array(z.string()),
          suggestions: z.array(z.string()),
        }),
      }),
      system: "You evaluate translations.",
      prompt: `Evaluate: Original: ${text} Translation: ${currentTranslation}`,
    });

    // Check quality
    if (evaluation.qualityScore >= 8 && evaluation.preservesTone) {
      break;
    }

    // Improve based on feedback
    const { text: improved } = await generateText({
      model,
      system: "You are an expert translator.",
      prompt: `Improve based on: ${evaluation.suggestions.join(", ")}
        Original: ${text}
        Current: ${currentTranslation}`,
    });

    currentTranslation = improved;
    iterations++;
  }

  return { translation: currentTranslation, iterations };
}
```

## Choosing Your Approach

| Factor              | Consideration                        |
| ------------------- | ------------------------------------ |
| **Flexibility**     | Agents for dynamic decisions         |
| **Control**         | Workflows for deterministic outcomes |
| **Error Tolerance** | More checks = more reliability       |
| **Cost**            | Complex systems = more LLM calls     |
| **Maintenance**     | Simpler = easier to debug            |

**Start simple, add complexity only when needed.**
