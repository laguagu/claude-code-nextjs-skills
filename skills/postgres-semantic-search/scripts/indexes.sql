-- Index Creation Scripts
-- Optimized indexes for semantic and hybrid search

-- ===========================================
-- 1. VECTOR INDEXES (HNSW - Recommended)
-- ===========================================

-- HNSW with Cosine similarity (most common for text embeddings)
CREATE INDEX IF NOT EXISTS documents_embedding_hnsw_idx
ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 200);

-- HNSW with L2 distance (Euclidean)
-- CREATE INDEX IF NOT EXISTS documents_embedding_hnsw_l2_idx
-- ON documents USING hnsw (embedding vector_l2_ops)
-- WITH (m = 16, ef_construction = 200);

-- HNSW with Inner Product (for normalized vectors)
-- CREATE INDEX IF NOT EXISTS documents_embedding_hnsw_ip_idx
-- ON documents USING hnsw (embedding vector_ip_ops)
-- WITH (m = 16, ef_construction = 200);

-- ===========================================
-- 2. HNSW FOR HALFVEC (3072 dimensions)
-- ===========================================

-- Optimized for text-embedding-3-large
-- Use when storage is important (50% memory savings)

/*
CREATE INDEX IF NOT EXISTS documents_embedding_halfvec_idx
ON documents USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops)
WITH (m = 24, ef_construction = 100);

-- Set query-time search depth
ALTER INDEX documents_embedding_halfvec_idx SET (ef_search = 80);
*/

-- ===========================================
-- 3. IVFFLAT INDEXES (Large datasets)
-- ===========================================

-- Use for datasets > 1M vectors where HNSW memory is prohibitive
-- lists = sqrt(rows) or rows/1000

/*
CREATE INDEX IF NOT EXISTS documents_embedding_ivfflat_idx
ON documents USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Set probes for query time (higher = better recall, slower)
SET ivfflat.probes = 10;
*/

-- ===========================================
-- 4. CHUNKS TABLE INDEXES
-- ===========================================

-- Vector index for chunks
CREATE INDEX IF NOT EXISTS chunks_embedding_hnsw_idx
ON chunks USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 200);

-- B-tree index for document_id lookups
CREATE INDEX IF NOT EXISTS chunks_document_id_idx
ON chunks (document_id);

-- ===========================================
-- 5. FULL-TEXT SEARCH INDEXES (GIN)
-- ===========================================

-- GIN index for PostgreSQL FTS (built-in)
CREATE INDEX IF NOT EXISTS documents_content_fts_idx
ON documents USING GIN (to_tsvector('simple', content));

-- With language-specific stemming
-- CREATE INDEX IF NOT EXISTS documents_content_fts_english_idx
-- ON documents USING GIN (to_tsvector('english', content));

-- CREATE INDEX IF NOT EXISTS documents_content_fts_finnish_idx
-- ON documents USING GIN (to_tsvector('finnish', content));

-- Chunks FTS index
CREATE INDEX IF NOT EXISTS chunks_content_fts_idx
ON chunks USING GIN (to_tsvector('simple', content));

-- ===========================================
-- 6. METADATA INDEXES (GIN for JSONB)
-- ===========================================

-- GIN index for JSONB metadata queries
CREATE INDEX IF NOT EXISTS documents_metadata_gin_idx
ON documents USING GIN (metadata);

CREATE INDEX IF NOT EXISTS chunks_metadata_gin_idx
ON chunks USING GIN (metadata);

-- ===========================================
-- 7. PARTIAL INDEXES (Category-specific)
-- ===========================================

-- Example: Index only for specific category
-- Useful when queries often filter by category

/*
CREATE INDEX IF NOT EXISTS documents_embedding_category_news_idx
ON documents USING hnsw (embedding vector_cosine_ops)
WHERE metadata->>'category' = 'news';

CREATE INDEX IF NOT EXISTS documents_embedding_category_legal_idx
ON documents USING hnsw (embedding vector_cosine_ops)
WHERE metadata->>'category' = 'legal';
*/

-- ===========================================
-- 8. ARRAY COLUMN INDEXES
-- ===========================================

-- If you have array columns for filtering (tags, categories, etc.)

/*
-- Tags array
ALTER TABLE documents ADD COLUMN tags TEXT[];

CREATE INDEX IF NOT EXISTS documents_tags_gin_idx
ON documents USING GIN (tags);

-- Usage: WHERE tags && ARRAY['tag1', 'tag2']
*/

-- ===========================================
-- 9. QUERY-TIME SETTINGS
-- ===========================================

-- HNSW search depth (higher = better recall, slower)
-- SET hnsw.ef_search = 100;

-- IVFFlat probes (higher = better recall, slower)
-- SET ivfflat.probes = 10;

-- Work memory for complex queries
-- SET work_mem = '256MB';

-- ===========================================
-- 10. INDEX MAINTENANCE
-- ===========================================

-- Reindex if performance degrades
-- REINDEX INDEX documents_embedding_hnsw_idx;

-- Analyze table for query planner
-- ANALYZE documents;

-- Check index size
-- SELECT pg_size_pretty(pg_relation_size('documents_embedding_hnsw_idx'));

-- ===========================================
-- 11. VERIFY INDEXES
-- ===========================================

-- List all indexes on documents table
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'documents'
ORDER BY indexname;

-- Check if index is being used (run EXPLAIN on your queries)
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM documents ORDER BY embedding <=> '[...]'::vector LIMIT 10;
