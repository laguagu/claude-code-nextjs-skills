-- Hybrid search: ParadeDB BM25 (pg_search) + pgvector, fused with weighted
-- reciprocal rank fusion. Requires pgvector, then pg_search (0.25+ depends on
-- pgvector's type), and a ParadeDB index on each searched table:
--
--   CREATE INDEX documents_search_idx ON documents
--   USING paradedb (id, title, content) WITH (key_field = 'id');
--   CREATE INDEX chunks_search_idx ON chunks
--   USING paradedb (id, content) WITH (key_field = 'id');
--
-- Syntax is pg_search's v2 API (||| match any term, pdb.score, pdb.snippet).
-- ParadeDB moves quickly: check https://www.paradedb.com/docs/llms.txt before
-- extending these. The vector arm here uses pgvector's own index; a vector
-- column placed inside the ParadeDB index is searched by ParadeDB instead.
-- hnsw.ef_search is not set here (default 40); the caller owns it.

-- Earlier versions had other signatures; beside the new ones every call
-- would be ambiguous.
DROP FUNCTION IF EXISTS hybrid_search_bm25(vector, text, integer, integer);
DROP FUNCTION IF EXISTS hybrid_search_bm25_highlighted(vector, text, integer, integer);
DROP FUNCTION IF EXISTS hybrid_search_chunks_bm25(vector, text, integer, integer);

CREATE OR REPLACE FUNCTION hybrid_search_bm25(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60,
    vector_weight FLOAT DEFAULT 1.0,
    keyword_weight FLOAT DEFAULT 1.0
)
RETURNS TABLE (
    id INTEGER, title TEXT, content TEXT, metadata JSONB,
    snippet TEXT,                       -- NULL when only the vector arm found the row
    vector_rank INTEGER, bm25_rank INTEGER, rrf_score FLOAT
)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    RETURN QUERY
    WITH vector_arm AS (
        SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.distance)::INTEGER AS rnk
        FROM (
            SELECT d.id, d.embedding <=> query_embedding AS distance
            FROM documents d
            WHERE query_embedding IS NOT NULL AND d.embedding IS NOT NULL
            ORDER BY distance
            LIMIT match_count * 3
        ) t
    ),
    bm25_arm AS (
        SELECT t.id, t.snip,
               ROW_NUMBER() OVER (ORDER BY t.score DESC, t.id)::INTEGER AS rnk
        FROM (
            SELECT d.id,
                   pdb.score(d.id) AS score,
                   pdb.snippet(d.content, start_tag => '<mark>', end_tag => '</mark>') AS snip
            FROM documents d
            WHERE v_has_text AND d.content ||| query_text
            ORDER BY pdb.score(d.id) DESC, d.id
            LIMIT match_count * 3
        ) t
    ),
    fused AS (
        SELECT COALESCE(v.id, b.id) AS doc_id,
               b.snip,
               v.rnk AS v_rank,
               b.rnk AS b_rank,
               (COALESCE(vector_weight / (rrf_k + v.rnk), 0)
                + COALESCE(keyword_weight / (rrf_k + b.rnk), 0))::FLOAT AS score
        FROM vector_arm v
        FULL OUTER JOIN bm25_arm b ON v.id = b.id
    )
    SELECT d.id, d.title, d.content, d.metadata, f.snip, f.v_rank, f.b_rank, f.score
    FROM fused f
    JOIN documents d ON d.id = f.doc_id
    ORDER BY f.score DESC, d.id
    LIMIT match_count;
END;
$$;

-- Chunks, one row per document: each arm keeps its best chunk per document
-- among its own candidates, then the arms are fused by document.
CREATE OR REPLACE FUNCTION hybrid_search_chunks_bm25(
    query_embedding vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 10,
    rrf_k INT DEFAULT 60,
    vector_weight FLOAT DEFAULT 1.0,
    keyword_weight FLOAT DEFAULT 1.0
)
RETURNS TABLE (
    chunk_id INTEGER, document_id INTEGER, document_title TEXT,
    chunk_content TEXT, snippet TEXT,
    vector_rank INTEGER, bm25_rank INTEGER, rrf_score FLOAT
)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_has_text BOOLEAN := query_text IS NOT NULL AND length(trim(query_text)) > 0;
BEGIN
    RETURN QUERY
    WITH vector_best AS (
        SELECT DISTINCT ON (t.doc_id) t.cid, t.doc_id, t.distance
        FROM (
            SELECT c.id AS cid, c.document_id AS doc_id,
                   c.embedding <=> query_embedding AS distance
            FROM chunks c
            WHERE query_embedding IS NOT NULL AND c.embedding IS NOT NULL
            ORDER BY distance
            LIMIT match_count * 5
        ) t
        ORDER BY t.doc_id, t.distance
    ),
    vector_arm AS (
        SELECT vb.cid, vb.doc_id,
               ROW_NUMBER() OVER (ORDER BY vb.distance)::INTEGER AS rnk
        FROM vector_best vb
    ),
    bm25_best AS (
        SELECT DISTINCT ON (t.doc_id) t.cid, t.doc_id, t.score, t.snip
        FROM (
            SELECT c.id AS cid, c.document_id AS doc_id,
                   pdb.score(c.id) AS score,
                   pdb.snippet(c.content, start_tag => '<mark>', end_tag => '</mark>') AS snip
            FROM chunks c
            WHERE v_has_text AND c.content ||| query_text
            ORDER BY pdb.score(c.id) DESC, c.id
            LIMIT match_count * 5
        ) t
        ORDER BY t.doc_id, t.score DESC
    ),
    bm25_arm AS (
        SELECT bb.cid, bb.doc_id, bb.snip,
               ROW_NUMBER() OVER (ORDER BY bb.score DESC, bb.doc_id)::INTEGER AS rnk
        FROM bm25_best bb
    ),
    fused AS (
        SELECT COALESCE(v.doc_id, b.doc_id) AS doc_id,
               COALESCE(b.cid, v.cid) AS cid,   -- prefer the chunk the snippet came from
               b.snip,
               v.rnk AS v_rank,
               b.rnk AS b_rank,
               (COALESCE(vector_weight / (rrf_k + v.rnk), 0)
                + COALESCE(keyword_weight / (rrf_k + b.rnk), 0))::FLOAT AS score
        FROM vector_arm v
        FULL OUTER JOIN bm25_arm b ON v.doc_id = b.doc_id
    )
    SELECT c.id, f.doc_id, d.title, c.content, f.snip, f.v_rank, f.b_rank, f.score
    FROM fused f
    JOIN chunks c ON c.id = f.cid
    JOIN documents d ON d.id = f.doc_id
    ORDER BY f.score DESC, f.doc_id
    LIMIT match_count;
END;
$$;

/*
SELECT * FROM hybrid_search_bm25('[0.1, 0.2, ...]'::vector(1536), 'search query');
SELECT * FROM hybrid_search_chunks_bm25($1, $2, 10, 60, vector_weight => 2.0);
*/
