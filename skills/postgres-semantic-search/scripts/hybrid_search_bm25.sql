-- Hybrid Search with pg_search BM25 + RRF
-- Requires: CREATE EXTENSION pg_search;

-- ===========================================
-- 1. SETUP BM25 INDEX
-- ===========================================

-- Create BM25 index on documents table
-- Run this AFTER creating the documents table

/*
-- Option A: Using paradedb.create_bm25 (pg_search)
CALL paradedb.create_bm25(
    index_name => 'documents_bm25',
    table_name => 'documents',
    key_field => 'id',
    text_fields => paradedb.field('content') ||
                   paradedb.field('title', tokenizer => paradedb.tokenizer('default'))
);

-- Option B: Using native BM25 index syntax (pg_search 0.20+)
CREATE INDEX documents_bm25_idx ON documents
USING bm25 (id, content, title)
WITH (key_field = 'id');
*/

-- ===========================================
-- 2. HYBRID SEARCH (BM25 + Vector + RRF)
-- ===========================================

CREATE OR REPLACE FUNCTION hybrid_search_bm25(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    vector_rank INTEGER,
    bm25_rank INTEGER,
    bm25_score FLOAT,
    rrf_score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_has_embedding BOOLEAN := query_embedding IS NOT NULL;
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    IF NOT v_has_embedding AND NOT v_has_text THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH vector_search AS (
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            ROW_NUMBER() OVER (ORDER BY d.embedding <=> query_embedding)::INTEGER AS rank
        FROM documents d
        WHERE v_has_embedding
          AND d.embedding IS NOT NULL
        ORDER BY d.embedding <=> query_embedding
        LIMIT match_count * 3
    ),
    bm25_search AS (
        -- pg_search BM25 search using @@@ operator
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            paradedb.score(d.id)::FLOAT AS bm25_score,
            ROW_NUMBER() OVER (ORDER BY paradedb.score(d.id) DESC)::INTEGER AS rank
        FROM documents d
        WHERE v_has_text
          AND d.id @@@ paradedb.match('content', query_text)
        ORDER BY paradedb.score(d.id) DESC
        LIMIT match_count * 3
    ),
    rrf_scores AS (
        SELECT
            COALESCE(v.id, b.id) AS id,
            COALESCE(v.title, b.title) AS title,
            COALESCE(v.content, b.content) AS content,
            COALESCE(v.metadata, b.metadata) AS metadata,
            v.rank AS vector_rank,
            b.rank AS bm25_rank,
            b.bm25_score,
            (
                COALESCE(1.0 / (rrf_k + v.rank), 0.0) +
                COALESCE(1.0 / (rrf_k + b.rank), 0.0)
            )::FLOAT AS rrf_score
        FROM vector_search v
        FULL OUTER JOIN bm25_search b ON v.id = b.id
    )
    SELECT
        r.id,
        r.title,
        r.content,
        r.metadata,
        r.vector_rank,
        r.bm25_rank,
        r.bm25_score,
        r.rrf_score
    FROM rrf_scores r
    ORDER BY r.rrf_score DESC
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 3. BM25 WITH SNIPPET HIGHLIGHTING
-- ===========================================

CREATE OR REPLACE FUNCTION hybrid_search_bm25_highlighted(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    snippet TEXT,
    metadata JSONB,
    vector_rank INTEGER,
    bm25_rank INTEGER,
    rrf_score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_has_embedding BOOLEAN := query_embedding IS NOT NULL;
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    IF NOT v_has_embedding AND NOT v_has_text THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH vector_search AS (
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            ROW_NUMBER() OVER (ORDER BY d.embedding <=> query_embedding)::INTEGER AS rank,
            NULL::TEXT AS snippet
        FROM documents d
        WHERE v_has_embedding
          AND d.embedding IS NOT NULL
        ORDER BY d.embedding <=> query_embedding
        LIMIT match_count * 3
    ),
    bm25_search AS (
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            ROW_NUMBER() OVER (ORDER BY paradedb.score(d.id) DESC)::INTEGER AS rank,
            paradedb.snippet(
                d.content,
                start_tag => '<mark>',
                end_tag => '</mark>'
            ) AS snippet
        FROM documents d
        WHERE v_has_text
          AND d.id @@@ paradedb.match('content', query_text)
        ORDER BY paradedb.score(d.id) DESC
        LIMIT match_count * 3
    ),
    combined AS (
        SELECT
            COALESCE(v.id, b.id) AS id,
            COALESCE(v.title, b.title) AS title,
            COALESCE(v.content, b.content) AS content,
            COALESCE(b.snippet, substring(COALESCE(v.content, b.content) from 1 for 200) || '...') AS snippet,
            COALESCE(v.metadata, b.metadata) AS metadata,
            v.rank AS vector_rank,
            b.rank AS bm25_rank,
            (
                COALESCE(1.0 / (rrf_k + v.rank), 0.0) +
                COALESCE(1.0 / (rrf_k + b.rank), 0.0)
            )::FLOAT AS rrf_score
        FROM vector_search v
        FULL OUTER JOIN bm25_search b ON v.id = b.id
    )
    SELECT
        c.id,
        c.title,
        c.content,
        c.snippet,
        c.metadata,
        c.vector_rank,
        c.bm25_rank,
        c.rrf_score
    FROM combined c
    ORDER BY c.rrf_score DESC
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 4. CHUNK-BASED HYBRID SEARCH (RAG)
-- ===========================================

-- For RAG systems with chunked documents
CREATE OR REPLACE FUNCTION hybrid_search_chunks_bm25(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60
)
RETURNS TABLE (
    chunk_id INTEGER,
    document_id INTEGER,
    document_title TEXT,
    chunk_content TEXT,
    snippet TEXT,
    vector_rank INTEGER,
    bm25_rank INTEGER,
    rrf_score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_has_embedding BOOLEAN := query_embedding IS NOT NULL;
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    IF NOT v_has_embedding AND NOT v_has_text THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH vector_search AS (
        SELECT
            c.id AS chunk_id,
            c.document_id,
            d.title AS document_title,
            c.content AS chunk_content,
            ROW_NUMBER() OVER (ORDER BY c.embedding <=> query_embedding)::INTEGER AS rank,
            -- Deduplicate by document, keep best chunk
            ROW_NUMBER() OVER (PARTITION BY c.document_id ORDER BY c.embedding <=> query_embedding) AS doc_rank
        FROM chunks c
        JOIN documents d ON d.id = c.document_id
        WHERE v_has_embedding
          AND c.embedding IS NOT NULL
        ORDER BY c.embedding <=> query_embedding
        LIMIT match_count * 5
    ),
    bm25_search AS (
        SELECT
            c.id AS chunk_id,
            c.document_id,
            d.title AS document_title,
            c.content AS chunk_content,
            paradedb.snippet(c.content, start_tag => '<mark>', end_tag => '</mark>') AS snippet,
            ROW_NUMBER() OVER (ORDER BY paradedb.score(c.id) DESC)::INTEGER AS rank,
            ROW_NUMBER() OVER (PARTITION BY c.document_id ORDER BY paradedb.score(c.id) DESC) AS doc_rank
        FROM chunks c
        JOIN documents d ON d.id = c.document_id
        WHERE v_has_text
          AND c.id @@@ paradedb.match('content', query_text)
        ORDER BY paradedb.score(c.id) DESC
        LIMIT match_count * 5
    ),
    -- Keep only best chunk per document
    vector_dedup AS (
        SELECT * FROM vector_search WHERE doc_rank = 1
    ),
    bm25_dedup AS (
        SELECT * FROM bm25_search WHERE doc_rank = 1
    ),
    combined AS (
        SELECT
            COALESCE(v.chunk_id, b.chunk_id) AS chunk_id,
            COALESCE(v.document_id, b.document_id) AS document_id,
            COALESCE(v.document_title, b.document_title) AS document_title,
            COALESCE(v.chunk_content, b.chunk_content) AS chunk_content,
            COALESCE(b.snippet, substring(COALESCE(v.chunk_content, b.chunk_content) from 1 for 200) || '...') AS snippet,
            v.rank AS vector_rank,
            b.rank AS bm25_rank,
            (
                COALESCE(1.0 / (rrf_k + v.rank), 0.0) +
                COALESCE(1.0 / (rrf_k + b.rank), 0.0)
            )::FLOAT AS rrf_score
        FROM vector_dedup v
        FULL OUTER JOIN bm25_dedup b ON v.document_id = b.document_id
    )
    SELECT
        c.chunk_id,
        c.document_id,
        c.document_title,
        c.chunk_content,
        c.snippet,
        c.vector_rank,
        c.bm25_rank,
        c.rrf_score
    FROM combined c
    ORDER BY c.rrf_score DESC
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 5. USAGE EXAMPLES
-- ===========================================

/*
-- First, create BM25 index
CALL paradedb.create_bm25(
    index_name => 'documents_bm25',
    table_name => 'documents',
    key_field => 'id',
    text_fields => paradedb.field('content')
);

-- Basic hybrid search
SELECT * FROM hybrid_search_bm25(
    '[0.1, 0.2, ...]'::vector(1536),
    'search query',
    10,
    60
);

-- With snippet highlighting
SELECT * FROM hybrid_search_bm25_highlighted(
    '[0.1, 0.2, ...]'::vector(1536),
    'search query',
    10,
    60
);

-- Chunk-based for RAG
SELECT * FROM hybrid_search_chunks_bm25(
    '[0.1, 0.2, ...]'::vector(1536),
    'search query',
    10,
    60
);
*/
