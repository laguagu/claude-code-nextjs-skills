-- Typo-tolerant search, autocomplete and fuzzy + semantic fusion (pg_trgm).
-- Requires: CREATE EXTENSION IF NOT EXISTS pg_trgm;
--
-- % compares whole strings (similarity), so a short query against a long title
-- or body scores near zero. <% compares the query with the best-matching run of
-- words (word_similarity) and is the right operator for prefixes and for
-- searching inside longer text. Both use the GUC thresholds
-- pg_trgm.similarity_threshold (0.3) and pg_trgm.word_similarity_threshold (0.6).

-- A trigram GIN index serves %, <%, LIKE and ILIKE, including patterns that
-- arrive as parameters. (A text_pattern_ops B-tree serves only left-anchored,
-- case-sensitive LIKE with a pattern known at plan time.)
CREATE INDEX IF NOT EXISTS documents_title_trgm_idx
ON documents USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS documents_content_trgm_idx
ON documents USING gin (content gin_trgm_ops);

-- Title by whole-string similarity, body by word similarity. (Earlier versions
-- returned more columns; a changed return type needs the DROP.)
DROP FUNCTION IF EXISTS fuzzy_search_trigram(text, double precision, integer);
CREATE OR REPLACE FUNCTION fuzzy_search_trigram(
    query_text TEXT,
    similarity_threshold FLOAT DEFAULT 0.3,
    max_results INT DEFAULT 10
)
RETURNS TABLE (id INT, title TEXT, content TEXT, score FLOAT)
LANGUAGE sql STABLE AS $$
    SELECT d.id, d.title, d.content,
           GREATEST(similarity(d.title, query_text),
                    word_similarity(query_text, d.content))::FLOAT AS score
    FROM documents d
    WHERE (d.title % query_text OR query_text <% d.content)
      AND GREATEST(similarity(d.title, query_text),
                   word_similarity(query_text, d.content)) > similarity_threshold
    ORDER BY 4 DESC, d.id
    LIMIT max_results;
$$;

-- Autocomplete: titles that start with the input first, then fuzzy matches.
-- LIKE metacharacters in the input are escaped so "50%" is not a wildcard.
CREATE OR REPLACE FUNCTION autocomplete_search(
    search_prefix TEXT,
    max_results INT DEFAULT 10
)
RETURNS TABLE (id INT, title TEXT, match_type TEXT, score FLOAT)
LANGUAGE sql STABLE AS $$
    WITH p AS (
        SELECT replace(replace(replace(search_prefix, '\', '\\'), '%', '\%'), '_', '\_') || '%' AS pattern
    )
    (
        SELECT d.id, d.title, 'prefix'::TEXT, 1.0::FLOAT
        FROM documents d, p
        WHERE d.title ILIKE p.pattern
        ORDER BY d.title
        LIMIT max_results
    )
    UNION ALL
    (
        SELECT d.id, d.title, 'fuzzy'::TEXT, word_similarity(search_prefix, d.title)::FLOAT
        FROM documents d, p
        WHERE search_prefix <% d.title
          AND d.title NOT ILIKE p.pattern
        ORDER BY 4 DESC, d.id
        LIMIT max_results
    )
    LIMIT max_results;
$$;

-- Fuzzy title matches + semantic matches, fused with RRF. Useful when users
-- misspell names that the embedding does not recognise.
CREATE OR REPLACE FUNCTION hybrid_search_fuzzy_semantic(
    query_text TEXT,
    query_embedding vector(1536),
    max_results INT DEFAULT 10,
    rrf_k INT DEFAULT 60
)
RETURNS TABLE (id INT, title TEXT, content TEXT, rrf_score FLOAT, fuzzy_rank INT, semantic_rank INT)
LANGUAGE sql STABLE AS $$
    WITH fuzzy AS (
        SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.sim DESC, t.id)::INT AS rnk
        FROM (
            SELECT d.id, word_similarity(query_text, d.title) AS sim
            FROM documents d
            WHERE query_text <% d.title
            ORDER BY sim DESC, d.id
            LIMIT 50
        ) t
    ),
    semantic AS (
        SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.distance)::INT AS rnk
        FROM (
            SELECT d.id, d.embedding <=> query_embedding AS distance
            FROM documents d
            WHERE d.embedding IS NOT NULL
            ORDER BY distance
            LIMIT 50
        ) t
    )
    SELECT d.id, d.title, d.content,
           (COALESCE(1.0 / (rrf_k + f.rnk), 0) + COALESCE(1.0 / (rrf_k + s.rnk), 0))::FLOAT,
           f.rnk, s.rnk
    FROM fuzzy f
    FULL OUTER JOIN semantic s ON f.id = s.id
    JOIN documents d ON d.id = COALESCE(f.id, s.id)
    ORDER BY 4 DESC, d.id
    LIMIT max_results;
$$;
