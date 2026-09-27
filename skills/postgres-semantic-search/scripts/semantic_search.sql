-- Semantic search functions (pgvector).
--
-- Shape: take LIMIT rows from the index inside a MATERIALIZED CTE and apply
-- the similarity threshold outside it. With the threshold in the same query
-- block the executor keeps scanning the index past it (pgvector's documented
-- form). Put every other filter INSIDE the CTE.
--
-- match_threshold is a cosine-similarity cutoff. Its useful value is
-- model-specific: a cutoff that suits one embedding model returns nothing for
-- another. Leave it NULL for plain top-k, or calibrate it on your eval set.
--
-- None of these set hnsw.ef_search (default 40, which also caps how many rows
-- the index returns). The caller owns that trade-off: SET LOCAL it in the same
-- transaction when a transaction pooler sits in front of Postgres.

CREATE OR REPLACE FUNCTION match_documents(
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT NULL,
    match_count INT DEFAULT 10
)
RETURNS TABLE (id INTEGER, title TEXT, content TEXT, metadata JSONB, similarity FLOAT)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH nearest AS MATERIALIZED (
        SELECT d.id, d.title, d.content, d.metadata,
               d.embedding <=> query_embedding AS distance
        FROM documents d
        WHERE d.embedding IS NOT NULL
        ORDER BY distance
        LIMIT match_count
    )
    SELECT n.id, n.title, n.content, n.metadata, (1 - n.distance)::FLOAT
    FROM nearest n
    WHERE match_threshold IS NULL OR (1 - n.distance) > match_threshold
    ORDER BY n.distance;
END;
$$;

-- Optional JSONB containment filter, e.g. '{"category": "news"}'.
-- A selective filter needs iterative scan, or the index hands back its first
-- ef_search candidates and the filter leaves fewer than match_count of them.
CREATE OR REPLACE FUNCTION match_documents_filtered(
    query_embedding vector(1536),
    filter_metadata JSONB DEFAULT NULL,
    match_threshold FLOAT DEFAULT NULL,
    match_count INT DEFAULT 10
)
RETURNS TABLE (id INTEGER, title TEXT, content TEXT, metadata JSONB, similarity FLOAT)
LANGUAGE plpgsql STABLE
SET hnsw.iterative_scan = 'relaxed_order'
AS $$
BEGIN
    RETURN QUERY
    WITH nearest AS MATERIALIZED (
        SELECT d.id, d.title, d.content, d.metadata,
               d.embedding <=> query_embedding AS distance
        FROM documents d
        WHERE d.embedding IS NOT NULL
          AND (filter_metadata IS NULL OR d.metadata @> filter_metadata)
        ORDER BY distance
        LIMIT match_count
    )
    SELECT n.id, n.title, n.content, n.metadata, (1 - n.distance)::FLOAT
    FROM nearest n
    WHERE match_threshold IS NULL OR (1 - n.distance) > match_threshold
    ORDER BY n.distance + 0;  -- relaxed order: re-sort; "+ 0" is needed on Postgres 17+
END;
$$;

-- Chunks with their parent document. Rank chunks through the index first and
-- join afterwards: a join inside the ordered scan can push the planner off it.
CREATE OR REPLACE FUNCTION match_chunks(
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT NULL,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    chunk_id INTEGER, document_id INTEGER, document_title TEXT,
    chunk_content TEXT, chunk_index INTEGER, similarity FLOAT
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH nearest AS MATERIALIZED (
        SELECT c.id, c.document_id, c.content, c.chunk_index,
               c.embedding <=> query_embedding AS distance
        FROM chunks c
        WHERE c.embedding IS NOT NULL
        ORDER BY distance
        LIMIT match_count
    )
    SELECT n.id, n.document_id, d.title, n.content, n.chunk_index,
           (1 - n.distance)::FLOAT
    FROM nearest n
    JOIN documents d ON d.id = n.document_id
    WHERE match_threshold IS NULL OR (1 - n.distance) > match_threshold
    ORDER BY n.distance;
END;
$$;

-- 2000 < N <= 4000 dimensions, stored at full precision as vector(3072) and
-- indexed as halfvec (see indexes.sql). The query must cast exactly like the
-- index expression, or the planner cannot use the index.
/*
CREATE OR REPLACE FUNCTION match_documents_halfvec(
    query_embedding vector(3072),
    match_threshold FLOAT DEFAULT NULL,
    match_count INT DEFAULT 10
)
RETURNS TABLE (id INTEGER, title TEXT, content TEXT, metadata JSONB, similarity FLOAT)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH nearest AS MATERIALIZED (
        SELECT d.id, d.title, d.content, d.metadata,
               d.embedding::halfvec(3072) <=> query_embedding::halfvec(3072) AS distance
        FROM documents d
        WHERE d.embedding IS NOT NULL
        ORDER BY distance
        LIMIT match_count
    )
    SELECT n.id, n.title, n.content, n.metadata, (1 - n.distance)::FLOAT
    FROM nearest n
    WHERE match_threshold IS NULL OR (1 - n.distance) > match_threshold
    ORDER BY n.distance;
END;
$$;
*/
