-- PostgreSQL Semantic Search Setup
-- Run this first on a new database

-- ===========================================
-- 1. REQUIRED EXTENSIONS
-- ===========================================

-- pgvector: Vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- unaccent: Language-agnostic text normalization (for FTS)
CREATE EXTENSION IF NOT EXISTS unaccent;

-- pg_search (optional): BM25 ranking - uncomment if available
-- CREATE EXTENSION IF NOT EXISTS pg_search;

-- ===========================================
-- 2. EXAMPLE TABLE STRUCTURE
-- ===========================================

-- Documents table with vector embedding
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::JSONB,

    -- Vector embedding (choose one based on your model)
    -- text-embedding-3-small: 1536 dimensions
    embedding vector(1536),

    -- For text-embedding-3-large with halfvec optimization:
    -- embedding halfvec(3072),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chunks table (for RAG with large documents)
CREATE TABLE IF NOT EXISTS chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- 3. AUTOMATIC TIMESTAMP UPDATE
-- ===========================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to documents table
DROP TRIGGER IF EXISTS documents_updated_at ON documents;
CREATE TRIGGER documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ===========================================
-- 4. VERIFY SETUP
-- ===========================================

-- Check installed extensions
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('vector', 'unaccent', 'pg_search');

-- Check pgvector version (should be 0.8.x for latest features)
-- SELECT vector_version();

-- ===========================================
-- 5. POST-BULK INSERT MAINTENANCE
-- ===========================================

-- IMPORTANT: Run after bulk inserts for best performance
-- VACUUM reclaims space, ANALYZE updates statistics

-- After inserting documents:
-- VACUUM ANALYZE documents;

-- After inserting chunks:
-- VACUUM ANALYZE chunks;

-- For large imports, consider:
-- 1. Insert data without indexes
-- 2. Create indexes after insert
-- 3. Run VACUUM ANALYZE

-- Example bulk import pattern:
/*
-- 1. Drop indexes temporarily
DROP INDEX IF EXISTS documents_embedding_hnsw_idx;

-- 2. Bulk insert (COPY is fastest)
COPY documents (content, embedding)
FROM '/path/to/data.csv' WITH (FORMAT csv);

-- Or batch INSERT
INSERT INTO documents (content, embedding)
VALUES
    ('text1', '[0.1, 0.2, ...]'::vector),
    ('text2', '[0.3, 0.4, ...]'::vector),
    ...;

-- 3. Recreate index
CREATE INDEX documents_embedding_hnsw_idx
ON documents USING hnsw (embedding vector_cosine_ops);

-- 4. Update statistics
VACUUM ANALYZE documents;
*/
