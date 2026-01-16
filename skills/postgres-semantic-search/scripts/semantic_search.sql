-- Semantic Search Functions
-- Pure vector similarity search using pgvector

-- ===========================================
-- 1. BASIC SEMANTIC SEARCH
-- ===========================================

-- Simple semantic search with threshold and limit
CREATE OR REPLACE FUNCTION match_documents(
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.title,
        d.content,
        d.metadata,
        (1 - (d.embedding <=> query_embedding))::FLOAT AS similarity
    FROM documents d
    WHERE d.embedding IS NOT NULL
      AND (1 - (d.embedding <=> query_embedding)) > match_threshold
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 2. SEMANTIC SEARCH WITH METADATA FILTER
-- ===========================================

-- Semantic search with optional JSONB metadata filter
CREATE OR REPLACE FUNCTION match_documents_filtered(
    query_embedding vector(1536),
    filter_metadata JSONB DEFAULT NULL,
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.title,
        d.content,
        d.metadata,
        (1 - (d.embedding <=> query_embedding))::FLOAT AS similarity
    FROM documents d
    WHERE d.embedding IS NOT NULL
      AND (1 - (d.embedding <=> query_embedding)) > match_threshold
      AND (filter_metadata IS NULL OR d.metadata @> filter_metadata)
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 3. DYNAMIC TABLE SEMANTIC SEARCH
-- ===========================================

-- Semantic search on any table with embedding column
CREATE OR REPLACE FUNCTION match_documents_dynamic(
    table_name TEXT,
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id INTEGER,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY EXECUTE FORMAT(
        'SELECT
            id,
            content,
            metadata,
            (1 - (embedding <=> $1))::FLOAT AS similarity
         FROM %I
         WHERE embedding IS NOT NULL
           AND (1 - (embedding <=> $1)) > $2
         ORDER BY embedding <=> $1
         LIMIT $3',
        table_name
    )
    USING query_embedding, match_threshold, match_count;
END;
$$;

-- ===========================================
-- 4. CHUNK-BASED SEMANTIC SEARCH (RAG)
-- ===========================================

-- Search chunks and return with parent document info
CREATE OR REPLACE FUNCTION match_chunks(
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    chunk_id INTEGER,
    document_id INTEGER,
    document_title TEXT,
    chunk_content TEXT,
    chunk_index INTEGER,
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id AS chunk_id,
        c.document_id,
        d.title AS document_title,
        c.content AS chunk_content,
        c.chunk_index,
        (1 - (c.embedding <=> query_embedding))::FLOAT AS similarity
    FROM chunks c
    JOIN documents d ON d.id = c.document_id
    WHERE c.embedding IS NOT NULL
      AND (1 - (c.embedding <=> query_embedding)) > match_threshold
    ORDER BY c.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ===========================================
-- 5. HALFVEC VERSION (3072 dimensions)
-- ===========================================

-- For text-embedding-3-large with memory optimization
-- Uncomment and modify table to use halfvec(3072)

/*
CREATE OR REPLACE FUNCTION match_documents_halfvec(
    query_embedding halfvec(3072),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.title,
        d.content,
        d.metadata,
        (1 - (d.embedding <=> query_embedding))::FLOAT AS similarity
    FROM documents d
    WHERE d.embedding IS NOT NULL
      AND (1 - (d.embedding <=> query_embedding)) > match_threshold
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
*/
