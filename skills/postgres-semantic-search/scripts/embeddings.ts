/**
 * Embedding utilities for PostgreSQL semantic search
 */

import OpenAI from 'openai';

const openai = new OpenAI();

// ============================================
// OpenAI Embeddings
// ============================================

export type EmbeddingModel =
  | 'text-embedding-3-small'  // 1536 dims, $0.02/1M tokens
  | 'text-embedding-3-large'; // 3072 dims, $0.13/1M tokens

export async function getEmbedding(
  text: string,
  model: EmbeddingModel = 'text-embedding-3-small'
): Promise<number[]> {
  const response = await openai.embeddings.create({
    model,
    input: text,
  });
  return response.data[0].embedding;
}

export async function getEmbeddings(
  texts: string[],
  model: EmbeddingModel = 'text-embedding-3-small'
): Promise<number[][]> {
  // OpenAI supports batch of up to 2048 inputs
  const response = await openai.embeddings.create({
    model,
    input: texts,
  });
  return response.data.map(d => d.embedding);
}

// ============================================
// Dimension Reduction (text-embedding-3 only)
// ============================================

export async function getEmbeddingReduced(
  text: string,
  dimensions: number = 1536
): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-large',
    input: text,
    dimensions, // Native dimension reduction
  });
  return response.data[0].embedding;
}

// ============================================
// PostgreSQL Helpers
// ============================================

/**
 * Format embedding for PostgreSQL vector type
 */
export function toPostgresVector(embedding: number[]): string {
  return `[${embedding.join(',')}]`;
}

/**
 * Parse PostgreSQL vector string to array
 */
export function fromPostgresVector(pgVector: string): number[] {
  return JSON.parse(pgVector.replace(/^\[/, '[').replace(/\]$/, ']'));
}

// ============================================
// Supabase Integration
// ============================================

import { createClient } from '@supabase/supabase-js';

export async function searchDocuments(
  supabase: ReturnType<typeof createClient>,
  query: string,
  options: {
    threshold?: number;
    limit?: number;
    filter?: Record<string, unknown>;
  } = {}
) {
  const { threshold = 0.7, limit = 10, filter } = options;

  const embedding = await getEmbedding(query);

  let rpcCall = supabase.rpc('match_documents', {
    query_embedding: embedding,
    match_threshold: threshold,
    match_count: limit,
  });

  if (filter) {
    rpcCall = supabase.rpc('match_documents_filtered', {
      query_embedding: embedding,
      filter_metadata: filter,
      match_threshold: threshold,
      match_count: limit,
    });
  }

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
  } = {}
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

import { sql } from 'drizzle-orm';
import type { PgDatabase } from 'drizzle-orm/pg-core';

export async function drizzleSemanticSearch<T extends PgDatabase<any>>(
  db: T,
  query: string,
  options: {
    table?: string;
    threshold?: number;
    limit?: number;
  } = {}
) {
  const { table = 'documents', threshold = 0.7, limit = 10 } = options;

  const embedding = await getEmbedding(query);
  const vectorStr = toPostgresVector(embedding);

  return db.execute(sql`
    SELECT
      id,
      content,
      metadata,
      1 - (embedding <=> ${vectorStr}::vector(1536)) AS similarity
    FROM ${sql.identifier(table)}
    WHERE embedding IS NOT NULL
      AND 1 - (embedding <=> ${vectorStr}::vector(1536)) > ${threshold}
    ORDER BY embedding <=> ${vectorStr}::vector(1536)
    LIMIT ${limit}
  `);
}
