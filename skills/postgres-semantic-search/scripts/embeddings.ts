/**
 * Embedding utilities for PostgreSQL semantic search.
 *
 * Uses the AI SDK so the provider is a one-line swap. Substitute
 * @ai-sdk/openai for @ai-sdk/cohere, @ai-sdk/google, @ai-sdk/mistral, a
 * Voyage/HuggingFace community provider, or a self-hosted OpenAI-compatible
 * endpoint — the rest of this file is unchanged.
 *
 * Pick the model from the provider's current docs and make sure your column's
 * dimension count matches it (see references/vector-types.md). Model names
 * rotate; do not copy one from memory.
 */

import { createOpenAI } from '@ai-sdk/openai';
import { embed, embedMany } from 'ai';
import { createClient } from '@supabase/supabase-js';
import { sql } from 'drizzle-orm';
import type { PgDatabase } from 'drizzle-orm/pg-core';

const provider = createOpenAI();

/** Must match the dimensions of the vector/halfvec column you insert into. */
const EMBEDDING_MODEL = provider.textEmbeddingModel('text-embedding-3-small');

export async function getEmbedding(text: string): Promise<number[]> {
  const { embedding } = await embed({ model: EMBEDDING_MODEL, value: text });
  return embedding;
}

export async function getEmbeddings(texts: string[]): Promise<number[][]> {
  // embedMany batches and parallelizes according to the provider's limits.
  const { embeddings } = await embedMany({
    model: EMBEDDING_MODEL,
    values: texts,
  });
  return embeddings;
}

// ============================================
// PostgreSQL Helpers
// ============================================

/** Format an embedding for the pgvector `vector` input syntax. */
export function toPostgresVector(embedding: number[]): string {
  return `[${embedding.join(',')}]`;
}

/** Parse a pgvector text output back to an array. */
export function fromPostgresVector(pgVector: string): number[] {
  return JSON.parse(pgVector);
}

// ============================================
// Supabase Integration
// ============================================

export async function searchDocuments(
  supabase: ReturnType<typeof createClient>,
  query: string,
  options: {
    threshold?: number;
    limit?: number;
    filter?: Record<string, unknown>;
  } = {},
) {
  const { threshold = 0.7, limit = 10, filter } = options;

  const embedding = await getEmbedding(query);

  const rpcCall = filter
    ? supabase.rpc('match_documents_filtered', {
        query_embedding: embedding,
        filter_metadata: filter,
        match_threshold: threshold,
        match_count: limit,
      })
    : supabase.rpc('match_documents', {
        query_embedding: embedding,
        match_threshold: threshold,
        match_count: limit,
      });

  const { data, error } = await rpcCall;

  if (error) throw error;
  return data;
}

export async function hybridSearch(
  supabase: ReturnType<typeof createClient>,
  query: string,
  options: {
    limit?: number;
    rrfK?: number;
    language?: string;
  } = {},
) {
  const { limit = 10, rrfK = 60, language = 'simple' } = options;

  const embedding = await getEmbedding(query);

  const { data, error } = await supabase.rpc('hybrid_search_fts', {
    query_embedding: embedding,
    query_text: query,
    match_count: limit,
    rrf_k: rrfK,
    fts_language: language,
  });

  if (error) throw error;
  return data;
}

// ============================================
// Drizzle ORM Integration
// ============================================

export async function drizzleSemanticSearch<T extends PgDatabase<any>>(
  db: T,
  query: string,
  options: {
    table?: string;
    threshold?: number;
    limit?: number;
  } = {},
) {
  const { table = 'documents', threshold = 0.7, limit = 10 } = options;

  const embedding = await getEmbedding(query);
  const vectorStr = toPostgresVector(embedding);

  // Distance filter sits outside a MATERIALIZED CTE so the index gets to
  // return `limit` rows before anything is discarded — see semantic_search.sql.
  return db.execute(sql`
    WITH nearest AS MATERIALIZED (
      SELECT id, content, metadata, embedding <=> ${vectorStr}::vector AS distance
      FROM ${sql.identifier(table)}
      WHERE embedding IS NOT NULL
      ORDER BY distance
      LIMIT ${limit}
    )
    SELECT id, content, metadata, 1 - distance AS similarity
    FROM nearest
    WHERE 1 - distance > ${threshold}
    ORDER BY distance
  `);
}
