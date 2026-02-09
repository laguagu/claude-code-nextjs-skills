-- Fuzzy Search Functions (pg_trgm)
-- Requires: CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ===========================================
-- 1. TRIGRAM INDEXES
-- ===========================================

-- GIN indexes for ILIKE and % operator (filtering)
CREATE INDEX IF NOT EXISTS documents_title_trgm_idx
ON documents USING gin (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS documents_content_trgm_idx
ON documents USING gin (content gin_trgm_ops);

-- GiST index for ORDER BY similarity (KNN ranking)
-- Use instead of GIN when you need sorted results
-- CREATE INDEX IF NOT EXISTS documents_title_trgm_gist_idx
-- ON documents USING gist (title gist_trgm_ops);

-- B-tree for prefix search (autocomplete)
CREATE INDEX IF NOT EXISTS documents_title_prefix_idx
ON documents (title text_pattern_ops);

-- ===========================================
-- 2. BASIC FUZZY SEARCH
-- ===========================================

-- Fuzzy search using trigram similarity
-- Returns documents where title or content fuzzy-matches the query
CREATE OR REPLACE FUNCTION fuzzy_search_trigram(
    query_text TEXT,
    similarity_threshold FLOAT DEFAULT 0.3,
    max_results INT DEFAULT 10
)
RETURNS TABLE (
    id INT,
    title TEXT,
    content TEXT,
    title_similarity FLOAT,
    content_similarity FLOAT,
    best_similarity FLOAT
)
LANGUAGE sql STABLE AS $$
    SELECT
        d.id,
        d.title,
        d.content,
        similarity(d.title, query_text) AS title_similarity,
        similarity(d.content, query_text) AS content_similarity,
        GREATEST(
            similarity(d.title, query_text),
            similarity(d.content, query_text)
        ) AS best_similarity
    FROM documents d
    WHERE d.title % query_text
       OR d.content % query_text
    ORDER BY best_similarity DESC
    LIMIT max_results;
$$;

-- Usage:
-- SELECT * FROM fuzzy_search_trigram('PostgreSQ', 0.3, 10);

-- ===========================================
-- 3. AUTOCOMPLETE SEARCH
-- ===========================================

-- Two-stage autocomplete: exact prefix first, fuzzy fallback second
CREATE OR REPLACE FUNCTION autocomplete_search(
    search_prefix TEXT,
    max_results INT DEFAULT 10
)
RETURNS TABLE (
    id INT,
    title TEXT,
    match_type TEXT,
    score FLOAT
)
LANGUAGE sql STABLE AS $$
    (
        -- Stage 1: Exact prefix matches (fastest, most relevant)
        SELECT d.id, d.title, 'prefix'::TEXT AS match_type, 1.0 AS score
        FROM documents d
        WHERE d.title ILIKE search_prefix || '%'
        ORDER BY d.title
        LIMIT max_results
    )
    UNION ALL
    (
        -- Stage 2: Fuzzy matches (typo tolerance)
        SELECT d.id, d.title, 'fuzzy'::TEXT AS match_type,
               similarity(d.title, search_prefix) AS score
        FROM documents d
        WHERE d.title % search_prefix
          AND d.title NOT ILIKE search_prefix || '%'
        ORDER BY similarity(d.title, search_prefix) DESC
        LIMIT max_results
    )
    LIMIT max_results;
$$;

-- Usage:
-- SELECT * FROM autocomplete_search('Post', 5);
-- SELECT * FROM autocomplete_search('Postgre', 10);

-- ===========================================
-- 4. FUZZY + SEMANTIC HYBRID SEARCH
-- ===========================================

-- Combines pg_trgm fuzzy matching with pgvector semantic search using RRF
CREATE OR REPLACE FUNCTION hybrid_search_fuzzy_semantic(
    query_text TEXT,
    query_embedding vector(1536),
    max_results INT DEFAULT 10,
    rrf_k INT DEFAULT 60
)
RETURNS TABLE (
    id INT,
    title TEXT,
    content TEXT,
    rrf_score FLOAT,
    fuzzy_rank INT,
    semantic_rank INT
)
LANGUAGE sql STABLE AS $$
    WITH fuzzy AS (
        SELECT d.id,
               ROW_NUMBER() OVER (
                   ORDER BY GREATEST(similarity(d.title, query_text), similarity(d.content, query_text)) DESC
               )::INT AS rank
        FROM documents d
        WHERE d.title % query_text OR d.content % query_text
        LIMIT 50
    ),
    semantic AS (
        SELECT d.id,
               ROW_NUMBER() OVER (ORDER BY d.embedding <=> query_embedding)::INT AS rank
        FROM documents d
        ORDER BY d.embedding <=> query_embedding
        LIMIT 50
    )
    SELECT
        d.id,
        d.title,
        d.content,
        (COALESCE(1.0 / (rrf_k + f.rank), 0.0) +
         COALESCE(1.0 / (rrf_k + s.rank), 0.0)) AS rrf_score,
        f.rank AS fuzzy_rank,
        s.rank AS semantic_rank
    FROM documents d
    LEFT JOIN fuzzy f ON d.id = f.id
    LEFT JOIN semantic s ON d.id = s.id
    WHERE f.id IS NOT NULL OR s.id IS NOT NULL
    ORDER BY rrf_score DESC
    LIMIT max_results;
$$;

-- Usage:
-- SELECT * FROM hybrid_search_fuzzy_semantic(
--     'PostgreSQL serch',
--     '[0.1, 0.2, ...]'::vector(1536),
--     10, 60
-- );

-- ===========================================
-- 5. WEIGHTED FTS (Title > Content)
-- ===========================================

-- Full-text search with title weighted higher than content
CREATE OR REPLACE FUNCTION weighted_fts_search(
    query_text TEXT,
    fts_language TEXT DEFAULT 'simple',
    max_results INT DEFAULT 10
)
RETURNS TABLE (
    id INT,
    title TEXT,
    content TEXT,
    rank FLOAT
)
LANGUAGE sql STABLE AS $$
    SELECT
        d.id,
        d.title,
        d.content,
        ts_rank(
            setweight(to_tsvector(fts_language::regconfig, COALESCE(d.title, '')), 'A') ||
            setweight(to_tsvector(fts_language::regconfig, d.content), 'B'),
            websearch_to_tsquery(fts_language::regconfig, query_text)
        ) AS rank
    FROM documents d
    WHERE (
        setweight(to_tsvector(fts_language::regconfig, COALESCE(d.title, '')), 'A') ||
        setweight(to_tsvector(fts_language::regconfig, d.content), 'B')
    ) @@ websearch_to_tsquery(fts_language::regconfig, query_text)
    ORDER BY rank DESC
    LIMIT max_results;
$$;

-- Usage:
-- SELECT * FROM weighted_fts_search('postgres full text', 'english', 10);
-- SELECT * FROM weighted_fts_search('postgres -mysql "replication"', 'english', 10);
