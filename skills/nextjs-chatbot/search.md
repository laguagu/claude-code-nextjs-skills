# SQL-First Search

## Contents

- [Prefer structured filters over freeform query](#prefer-structured-filters-over-freeform-query)
- [No silent SQL fallbacks](#no-silent-sql-fallbacks)
- [When SQL-first beats RAG](#when-sql-first-beats-rag)
- [Pattern: weighted FTS + trigram fallback](#pattern-weighted-fts--trigram-fallback)
- [Provider alias normalization](#provider-alias-normalization)
- [Query builder factory](#query-builder-factory-enables-sql-level-benchmarks)
- [Tool definition](#tool-definition)
- [Separate search from detail lookup](#separate-search-from-detail-lookup)
- [When to use RAG instead](#when-to-use-rag-instead)

## Prefer structured filters over freeform query

Applies when the catalog has a known vocabulary (tags, categories, input formats) and same question → same result matters. Skip if you're doing open-ended search / autocomplete / RAG retrieval — those genuinely need freeform input.

Primary input = structured filters; `freeText` is a fallback. Same intent → same filter shape → same SQL → same result set across runs. A `query: z.string()` input lets the LLM rephrase the same question differently each turn and, combined with FTS AND-matching, produces very different result sets; on one `gpt-5.4` chatbot this meant 11 % stability on "What X are available?", vs. 100 % after switching to `tags: string[]` with array overlap.

```ts
export const searchComponentsInput = z.object({
  tags: z.array(z.string()).optional()
    .describe("Filter by tags (array overlap). Prefer over freeText when a canonical tag matches intent."),
  category: z.string().optional(),
  inputFormat: z.string().optional(),
  freeText: z.string().optional()
    .describe("Fallback only. Use when no tag fits. 1–2 keywords."),
});
```

```sql
WHERE c.tags && $1::text[]   -- ANY overlap; deterministic
  -- fall through to weighted FTS + trigram only if freeText is present
```

Inject a canonical vocabulary block + a 5–10 row mapping table into the system prompt (auto-generated from the catalog so it scales as data grows). Example mapping:

```
| User intent | Tool call |
|---|---|
| "What RAG components are available?" | searchComponents({ tags: ["rag"] }) |
| "Which PDF parser should I use?"     | searchComponents({ tags: ["parser","pdf"] }) |
| "End-to-end pipelines"               | searchComponents({ category: "software_module" }) |

Rules: prefer tags over freeText; never combine them; omit filters that don't narrow the search;
if the user writes in another language, translate intent to English tags (don't pass foreign words).
```

## No silent SQL fallbacks

For catalog-style tools where stability matters, avoid sequential retries that silently change the SQL ("if 0 rows, drop filters"; "simplify to longest non-stopword"). Each retry makes results depend on token length rather than intent. For example, dropping a `category` filter then simplifying `"RAG retrieval augmented generation components"` to `"generation"` caused ILIKE `%generation%` to match "Answer Generation" in unrelated pipeline descriptions — different runs hit different fallback levels.

A single SQL statement with `ILIKE OR FTS OR trigram` conditions is fine (deterministic for one input). Sequential retries with different inputs are the problem. For autocomplete, fuzzy-match UX, or "show *something* even if imperfect" scenarios, silent fallbacks are OK — they improve perceived responsiveness at the cost of strict stability.

## When SQL-first beats RAG

Use PostgreSQL FTS + trigram instead of vector embeddings when:

- Data is **structured and bounded** (a service catalog, topic list, contact directory)
- You need **deterministic, debuggable** results — same query = same result every time
- You want to **benchmark at the SQL level** without a live LLM (fast, no cost)
- The domain vocabulary is **consistent** (fuzzy matching handles typos well)
- You want **zero embedding cost** and no vector index maintenance

RAG/pgvector is better when: content is unstructured prose (documents, FAQs), semantic meaning matters more than keywords, or the data volume is large enough that SQL ranking becomes unwieldy.

## Pattern: weighted FTS + trigram fallback

```sql
-- Weighted full-text search across multiple columns
SELECT
  id,
  name,
  description,
  ts_rank(
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(provider, '')), 'C'),
    plainto_tsquery('simple', $1)
  ) AS fts_score,
  -- Trigram similarity as fallback/boost for typos
  greatest(
    similarity(name, $1),
    similarity(provider, $1)
  ) AS trgm_score
FROM services
WHERE
  -- FTS match OR trigram similarity above threshold
  (
    to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(provider, ''))
    @@ plainto_tsquery('simple', $1)
  )
  OR name % $1          -- pg_trgm: % operator uses similarity threshold (default 0.3)
  OR provider % $1
ORDER BY (fts_score * 2 + trgm_score) DESC
LIMIT 20;
```

Required PostgreSQL extensions:
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

Required indexes:
```sql
-- GIN index for full-text search
CREATE INDEX ON services USING GIN(
  to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(provider, ''))
);
-- GIN trigram indexes for fuzzy matching
CREATE INDEX ON services USING GIN(name gin_trgm_ops);
CREATE INDEX ON services USING GIN(provider gin_trgm_ops);
```

## Provider alias normalization

Normalize user input before querying so common abbreviations and variant spellings resolve to canonical names:

```ts
// lib/ai/tools/normalize-provider.ts
const PROVIDER_ALIASES: Record<string, string> = {
  // Add your domain-specific aliases here
  // "shortname": "Full Official Name",
};

export function normalizeProvider(input: string): string {
  const lower = input.toLowerCase().trim();
  return PROVIDER_ALIASES[lower] ?? input;
}
```

## Query builder factory (enables SQL-level benchmarks)

Separate query construction from execution so benchmarks can test SQL without an LLM:

```ts
// lib/ai/tools/search-services.ts

// Returns the SQL string + params — testable without a DB connection
export function buildSearchServicesQuery(params: { query: string; provider?: string }) {
  const { query, provider } = params;
  // ... build parameterized SQL
  return { sql, values };
}

// Actual DB execution
export async function searchServices(params: { query: string; provider?: string }) {
  const { sql, values } = buildSearchServicesQuery(params);
  return db.execute(sql, values);
}
```

Benchmark test example:
```ts
// benchmarks/search.bench.ts
const { sql, values } = buildSearchServicesQuery({ query: "supercomputing" });
// Inspect SQL structure without hitting DB — fast, deterministic
```

## Tool definition

```ts
export const searchServicesTool = tool({
  description: "Search services by keyword, provider, or category",
  inputSchema: z.object({
    query: z.string().describe("Search terms"),
    provider: z.string().optional().describe("Filter by provider name"),
    category: z.string().optional(),
  }),
  outputSchema: z.object({
    services: z.array(serviceSchema),
    total: z.number(),
  }),
  execute: async ({ query, provider, category }) => {
    const normalizedProvider = provider ? normalizeProvider(provider) : undefined;
    return searchServices({ query, provider: normalizedProvider, category });
  },
});
```

## Separate search from detail lookup

Keep search and detail retrieval as separate tools:

- `searchServices` — ranked FTS/trigram results, returns list with scores
- `getServiceDetails` — exact ID lookup, no ranking logic

This keeps the ranking logic isolated and makes the detail tool fast and predictable. The agent decides when to drill down.

## When to use RAG instead

If content is unstructured prose (documents, FAQs, long text), use embeddings + pgvector rather than FTS.

### Schema addition

```ts
// lib/db/schema/embeddings.ts
import { pgTable, text, vector, index } from 'drizzle-orm/pg-core';

export const embeddings = pgTable('embeddings', {
  id: text('id').primaryKey(),
  resourceId: text('resource_id').references(() => resources.id, { onDelete: 'cascade' }),
  content: text('content').notNull(),
  embedding: vector('embedding', { dimensions: 1536 }).notNull(),
}, (t) => ({
  embeddingIndex: index('embeddingIndex').using('hnsw', t.embedding.op('vector_cosine_ops')),
}));
```

Requires: `CREATE EXTENSION IF NOT EXISTS vector;`

### Embedding utilities (AI SDK v6)

```ts
// lib/ai/embedding.ts
import { embed, embedMany } from 'ai';
import { openai } from '@ai-sdk/openai';
import { cosineDistance, desc, gt, sql } from 'drizzle-orm';
import { embeddings } from '../db/schema/embeddings';

const embeddingModel = openai.embedding('text-embedding-3-small');

export async function generateEmbedding(value: string): Promise<number[]> {
  const { embedding } = await embed({ model: embeddingModel, value });
  return embedding;
}

export async function generateEmbeddings(content: string) {
  const chunks = content.split('.').map(c => c.trim()).filter(Boolean);
  const { embeddings: vecs } = await embedMany({ model: embeddingModel, values: chunks });
  return vecs.map((e, i) => ({ content: chunks[i], embedding: e }));
}

export async function findRelevantContent(query: string) {
  const queryEmbedding = await generateEmbedding(query);
  const similarity = sql<number>`1 - (${cosineDistance(embeddings.embedding, queryEmbedding)})`;
  return db
    .select({ content: embeddings.content, similarity })
    .from(embeddings)
    .where(gt(similarity, 0.5))
    .orderBy(desc(similarity))
    .limit(4);
}
```

For advanced patterns (HNSW tuning, hybrid BM25+vector, reranking) → see `/postgres-semantic-search`.

