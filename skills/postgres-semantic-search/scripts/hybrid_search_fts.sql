-- Hybrid search: Postgres full-text search + pgvector, fused with weighted
-- reciprocal rank fusion. Needs no extension beyond pgvector.
--
-- * Either input may be NULL or empty. The missing arm contributes nothing, so
--   the same function serves vector-only and keyword-only calls.
-- * The keyword arm ORs the query's terms (plainto_tsquery, then & -> |) and
--   lets ts_rank_cd reward rows that match more of them. Both stock parsers AND
--   every term, which leaves a long question with zero keyword hits. If the UI
--   exposes quotes, OR or -exclusions, use websearch_to_tsquery unchanged.
-- * to_tsvector runs per row here, so no index serves the keyword arm. On a
--   large table, compare against a stored, GIN-indexed tsvector column instead
--   (references/keyword-search.md).
-- * Accent folding belongs in the text search configuration, not here: pass a
--   custom config such as french_unaccent. Never fold Finnish, Swedish, German
--   or Turkish, where the marked letters are different letters.
-- * Each arm adds weight / (rrf_k + rank). Equal weights are a starting point,
--   not a result: compare against vector-only on your eval set.
-- * hnsw.ef_search is not set here (default 40). SET LOCAL it in the caller's
--   transaction if the vector arm needs more than 40 candidates.

-- The earlier five-argument version must go: beside the new one, every
-- five-argument call would be ambiguous. hybrid_search_weighted, which this
-- function's weights replace, failed on every call ("id" is ambiguous).
DROP FUNCTION IF EXISTS hybrid_search_fts(vector, text, integer, integer, text);
DROP FUNCTION IF EXISTS hybrid_search_weighted(vector, text, integer, double precision, double precision, text);

CREATE OR REPLACE FUNCTION hybrid_search_fts(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60,
    fts_language TEXT DEFAULT 'simple',   -- 'simple', 'english', 'finnish', a custom config...
    vector_weight FLOAT DEFAULT 1.0,
    keyword_weight FLOAT DEFAULT 1.0
)
RETURNS TABLE (
    id INTEGER, title TEXT, content TEXT, metadata JSONB,
    vector_rank INTEGER, keyword_rank INTEGER, rrf_score FLOAT
)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_tsq tsquery;
BEGIN
    IF query_text IS NOT NULL AND length(trim(query_text)) > 0 THEN
        v_tsq := replace(
            plainto_tsquery(fts_language::regconfig, query_text)::text, ' & ', ' | '
        )::tsquery;
        IF numnode(v_tsq) = 0 THEN   -- only stop words
            v_tsq := NULL;
        END IF;
    END IF;

    RETURN QUERY
    WITH vector_arm AS (
        -- Rank the already-limited candidates: a window beside ORDER BY ... LIMIT
        -- has to see every row first, which rules out a top-N sort.
        SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.distance)::INTEGER AS rnk
        FROM (
            SELECT d.id, d.embedding <=> query_embedding AS distance
            FROM documents d
            WHERE query_embedding IS NOT NULL AND d.embedding IS NOT NULL
            ORDER BY distance
            LIMIT match_count * 3
        ) t
    ),
    keyword_arm AS (
        SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.score DESC, t.id)::INTEGER AS rnk
        FROM (
            SELECT d.id, ts_rank_cd(to_tsvector(fts_language::regconfig, d.content), v_tsq) AS score
            FROM documents d
            WHERE v_tsq IS NOT NULL
              AND to_tsvector(fts_language::regconfig, d.content) @@ v_tsq
            ORDER BY score DESC, d.id
            LIMIT match_count * 3
        ) t
    ),
    fused AS (
        SELECT COALESCE(v.id, k.id) AS doc_id,
               v.rnk AS v_rank,
               k.rnk AS k_rank,
               (COALESCE(vector_weight / (rrf_k + v.rnk), 0)
                + COALESCE(keyword_weight / (rrf_k + k.rnk), 0))::FLOAT AS score
        FROM vector_arm v
        FULL OUTER JOIN keyword_arm k ON v.id = k.id
    )
    SELECT d.id, d.title, d.content, d.metadata, f.v_rank, f.k_rank, f.score
    FROM fused f
    JOIN documents d ON d.id = f.doc_id
    ORDER BY f.score DESC, d.id
    LIMIT match_count;
END;
$$;

/*
SELECT * FROM hybrid_search_fts('[0.1, 0.2, ...]'::vector(1536), 'search query');
SELECT * FROM hybrid_search_fts(NULL, 'keyword only', 10);
-- Weight the vector arm, a long question in Finnish:
SELECT * FROM hybrid_search_fts($1, $2, 10, 60, 'finnish', vector_weight => 3.0);
*/
