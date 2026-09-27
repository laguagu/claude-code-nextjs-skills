-- Indexes for the example schema. Build vector indexes after bulk loads.
-- Parameters are pgvector defaults unless a comment says otherwise; tune
-- against exact search on your own queries (references/pgvector.md).
-- Trigram indexes live in fuzzy_search.sql, ParadeDB indexes in
-- hybrid_search_bm25.sql.

-- Vector: HNSW, cosine. The operator class must match the query operator
-- (<=> cosine_ops, <-> l2_ops, <#> ip_ops) or the index is not used.
CREATE INDEX IF NOT EXISTS documents_embedding_hnsw_idx
ON documents USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS chunks_embedding_hnsw_idx
ON chunks USING hnsw (embedding vector_cosine_ops);

-- 2000 < N <= 4000: keep vector(N) and index a halfvec cast. Queries must use
-- the identical expression: ORDER BY embedding::halfvec(3072) <=> $1::halfvec(3072)
-- CREATE INDEX ON documents USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops);

-- IVFFlat: less memory and faster builds than HNSW, lower recall at equal speed.
-- Build only once the table holds representative data. Starting points from
-- pgvector: lists = rows / 1000 up to 1M rows, sqrt(rows) above; probes = sqrt(lists).
-- CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- A few fixed filter values: one partial index per value beats filtering a
-- shared index. Many values or per-tenant isolation: partition instead.
-- CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
-- WHERE (metadata->>'category') = 'news';

-- Full-text search. The expression must match the query's to_tsvector call
-- exactly, config included. A stored tsvector column is simpler to keep in sync:
--   ALTER TABLE documents ADD COLUMN tsv tsvector GENERATED ALWAYS AS
--     (setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
--      setweight(to_tsvector('simple', content), 'B')) STORED;
--   CREATE INDEX ON documents USING gin (tsv);
CREATE INDEX IF NOT EXISTS documents_content_fts_idx
ON documents USING gin (to_tsvector('simple', content));

CREATE INDEX IF NOT EXISTS chunks_content_fts_idx
ON chunks USING gin (to_tsvector('simple', content));

-- Metadata filters (@> containment). Chunk lookups by document use the
-- UNIQUE (document_id, chunk_index) index from setup.sql.
CREATE INDEX IF NOT EXISTS documents_metadata_gin_idx
ON documents USING gin (metadata);
