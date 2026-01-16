-- Hybrid Search with PostgreSQL Full-Text Search + RRF
-- No extra extensions needed (except pgvector + unaccent)

-- ===========================================
-- 1. HYBRID SEARCH (FTS + Vector + RRF)
-- ===========================================

CREATE OR REPLACE FUNCTION hybrid_search_fts(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60,
    fts_language TEXT DEFAULT 'simple'  -- 'simple', 'english', 'finnish', etc.
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    vector_rank INTEGER,
    keyword_rank INTEGER,
    rrf_score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_has_embedding BOOLEAN := query_embedding IS NOT NULL;
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    -- If neither search method provided, return empty
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
    keyword_search AS (
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            ROW_NUMBER() OVER (
                ORDER BY ts_rank_cd(
                    to_tsvector(fts_language, unaccent(d.content)),
                    plainto_tsquery(fts_language, unaccent(query_text))
                ) DESC
            )::INTEGER AS rank
        FROM documents d
        WHERE v_has_text
          AND to_tsvector(fts_language, unaccent(d.content))
              @@ plainto_tsquery(fts_language, unaccent(query_text))
        ORDER BY ts_rank_cd(
            to_tsvector(fts_language, unaccent(d.content)),
            plainto_tsquery(fts_language, unaccent(query_text))
        ) DESC
        LIMIT match_count * 3
    ),
    rrf_scores AS (
        SELECT
            COALESCE(v.id, k.id) AS id,
            COALESCE(v.title, k.title) AS title,
            COALESCE(v.content, k.content) AS content,
            COALESCE(v.metadata, k.metadata) AS metadata,
            v.rank AS vector_rank,
            k.rank AS keyword_rank,
            (
                COALESCE(1.0 / (rrf_k + v.rank), 0.0) +
                COALESCE(1.0 / (rrf_k + k.rank), 0.0)
            )::FLOAT AS rrf_score
        FROM vector_search v
        FULL OUTER JOIN keyword_search k ON v.id = k.id
    )
    SELECT
        r.id,
        r.title,
        r.content,
        r.metadata,
        r.vector_rank,
        r.keyword_rank,
        r.rrf_score
    FROM rrf_scores r
    ORDER BY r.rrf_score DESC
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 2. WEIGHTED LINEAR COMBINATION
-- ===========================================

CREATE OR REPLACE FUNCTION hybrid_search_weighted(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    semantic_weight FLOAT DEFAULT 0.5,
    keyword_weight FLOAT DEFAULT 0.5,
    fts_language TEXT DEFAULT 'simple'
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    semantic_score FLOAT,
    keyword_score FLOAT,
    combined_score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH semantic AS (
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            (1 - (d.embedding <=> query_embedding))::FLOAT AS score
        FROM documents d
        WHERE d.embedding IS NOT NULL
        ORDER BY d.embedding <=> query_embedding
        LIMIT match_count * 3
    ),
    keyword AS (
        SELECT
            d.id,
            ts_rank_cd(
                to_tsvector(fts_language, unaccent(d.content)),
                plainto_tsquery(fts_language, unaccent(query_text))
            )::FLOAT AS score
        FROM documents d
        WHERE to_tsvector(fts_language, unaccent(d.content))
              @@ plainto_tsquery(fts_language, unaccent(query_text))
    ),
    -- Normalize keyword scores to 0-1 range
    keyword_normalized AS (
        SELECT
            id,
            CASE
                WHEN MAX(score) OVER () > 0
                THEN score / MAX(score) OVER ()
                ELSE 0
            END AS score
        FROM keyword
    )
    SELECT
        s.id,
        s.title,
        s.content,
        s.metadata,
        s.score AS semantic_score,
        COALESCE(k.score, 0)::FLOAT AS keyword_score,
        (semantic_weight * s.score + keyword_weight * COALESCE(k.score, 0))::FLOAT AS combined_score
    FROM semantic s
    LEFT JOIN keyword_normalized k ON s.id = k.id
    ORDER BY (semantic_weight * s.score + keyword_weight * COALESCE(k.score, 0)) DESC
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 3. FALLBACK SEARCH (Vector OR Keyword)
-- ===========================================

CREATE OR REPLACE FUNCTION hybrid_search_fallback(
    query_embedding vector(1536) DEFAULT NULL,
    query_text TEXT DEFAULT NULL,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60,
    fts_language TEXT DEFAULT 'simple'
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    search_type TEXT,
    score FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_has_embedding BOOLEAN := query_embedding IS NOT NULL;
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    -- Vector-only search
    IF v_has_embedding AND NOT v_has_text THEN
        RETURN QUERY
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            'vector'::TEXT AS search_type,
            (1 - (d.embedding <=> query_embedding))::FLOAT AS score
        FROM documents d
        WHERE d.embedding IS NOT NULL
        ORDER BY d.embedding <=> query_embedding
        LIMIT match_count;
        RETURN;
    END IF;

    -- Keyword-only search
    IF v_has_text AND NOT v_has_embedding THEN
        RETURN QUERY
        SELECT
            d.id,
            d.title,
            d.content,
            d.metadata,
            'keyword'::TEXT AS search_type,
            ts_rank_cd(
                to_tsvector(fts_language, unaccent(d.content)),
                plainto_tsquery(fts_language, unaccent(query_text))
            )::FLOAT AS score
        FROM documents d
        WHERE to_tsvector(fts_language, unaccent(d.content))
              @@ plainto_tsquery(fts_language, unaccent(query_text))
        ORDER BY score DESC
        LIMIT match_count;
        RETURN;
    END IF;

    -- Full hybrid search
    IF v_has_embedding AND v_has_text THEN
        RETURN QUERY
        SELECT
            h.id,
            h.title,
            h.content,
            h.metadata,
            'hybrid'::TEXT AS search_type,
            h.rrf_score AS score
        FROM hybrid_search_fts(query_embedding, query_text, match_count, rrf_k, fts_language) h;
        RETURN;
    END IF;

    -- No search criteria provided
    RETURN;
END;
$$;

-- ===========================================
-- 4. USAGE EXAMPLES
-- ===========================================

/*
-- Hybrid search with RRF
SELECT * FROM hybrid_search_fts(
    '[0.1, 0.2, ...]'::vector(1536),
    'search query',
    10,
    60,
    'simple'
);

-- Weighted search (60% semantic, 40% keyword)
SELECT * FROM hybrid_search_weighted(
    '[0.1, 0.2, ...]'::vector(1536),
    'search query',
    10,
    0.6,
    0.4,
    'english'
);

-- Fallback search (vector-only if no text)
SELECT * FROM hybrid_search_fallback(
    '[0.1, 0.2, ...]'::vector(1536),
    '',
    10
);
*/
