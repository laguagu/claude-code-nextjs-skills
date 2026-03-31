# SQL-First Search

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

