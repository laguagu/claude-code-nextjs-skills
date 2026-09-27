-- Extensions and the example schema every other script assumes.
-- Rename tables/columns and change vector(1536) to your model's dimension
-- count in all scripts at once; the functions hard-code both.

CREATE EXTENSION IF NOT EXISTS vector;    -- pgvector
CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- fuzzy_search.sql, trigram indexes
-- CREATE EXTENSION IF NOT EXISTS unaccent;   -- only for a custom FTS config, see references/keyword-search.md
-- CREATE EXTENSION IF NOT EXISTS pg_search;  -- hybrid_search_bm25.sql (ParadeDB); needs pgvector first

CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    -- N <= 2000: vector(N). 2000 < N <= 4000: halfvec(N), or keep vector(N)
    -- and index a halfvec cast (references/pgvector.md). NULLs are not indexed.
    embedding vector(1536)
);

CREATE TABLE IF NOT EXISTS chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    UNIQUE (document_id, chunk_index)
);

-- Bulk loads: insert first, then build the vector index (indexes.sql).
-- An IVFFlat index built on an empty or tiny table picks bad lists and
-- silently returns too few rows.

SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('vector', 'pg_trgm', 'unaccent', 'pg_search');
