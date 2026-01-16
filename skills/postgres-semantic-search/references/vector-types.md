# Vector Types and Dimensions

## Vector Types in pgvector

### vector (float4)

Standard 32-bit floating-point vector.

```sql
-- Column definition
embedding vector(1536)

-- Index
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

**Properties:**
- 32 bits (4 bytes) per dimension
- Full precision
- Max dimensions: 16,000 (HNSW), 2,000 (IVFFlat)

**Memory per row:**
- 1536 dims: ~6 KB
- 3072 dims: ~12 KB

### halfvec (float2)

Half-precision 16-bit floating-point vector. Available in pgvector 0.7.0+.

```sql
-- Column definition
embedding halfvec(3072)

-- Index (note: different operator class)
CREATE INDEX ON documents USING hnsw (embedding halfvec_cosine_ops);

-- Or cast from vector
CREATE INDEX ON documents USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops);
```

**Properties:**
- 16 bits (2 bytes) per dimension
- Slightly reduced precision (negligible for embeddings)
- Max dimensions: 4,000 (HNSW)
- **50% memory savings**

**Memory per row:**
- 3072 dims: ~6 KB (same as vector(1536))

### bit (binary vectors)

Binary vectors for binary quantization. Pgvector 0.8.0+.

```sql
embedding bit(3072)

-- Index
CREATE INDEX ON documents USING hnsw (embedding bit_hamming_ops);
```

**Properties:**
- 1 bit per dimension
- Max dimensions: 64,000
- Use for extreme compression

## Embedding Model Dimensions

| Model | Dimensions | Recommended Type |
|-------|-----------|------------------|
| text-embedding-3-small | 1536 | `vector(1536)` |
| text-embedding-3-large | 3072 | `halfvec(3072)` |

> **Note:** For other embedding models (Cohere, Voyage AI, Mistral, etc.), consult the model provider's documentation for dimension specifications. Use `vector(dimensions)` for models with ≤ 2000 dimensions, or `halfvec(dimensions)` for larger models requiring memory optimization.

## Dimension Truncation

OpenAI text-embedding-3 models support native dimension reduction:

```python
# Python - truncate at API level
response = openai.embeddings.create(
    model="text-embedding-3-large",
    input=text,
    dimensions=1536  # Truncate from 3072 to 1536
)
```

```sql
-- SQL - truncate stored embedding
SELECT embedding[:1536] AS truncated
FROM documents;
```

**Trade-offs:**
- 3072 dims: Best quality, most memory
- 1536 dims: Good balance
- 768 dims: Fast, lower recall

## Choosing Vector Type

### Use `vector(1536)` when:
- Using text-embedding-3-small
- Storage is not a concern
- Need maximum compatibility

### Use `halfvec(3072)` when:
- Using text-embedding-3-large
- Want quality of 3072 dims with memory of 1536
- pgvector 0.7.0+ available

### Use `bit` when:
- Extreme scale (millions of vectors)
- Can accept lower recall
- Binary quantization is acceptable

## Conversion Examples

```sql
-- vector to halfvec
SELECT embedding::halfvec(1536) FROM documents;

-- halfvec to vector (for functions expecting vector)
SELECT embedding::vector(1536) FROM documents;

-- Truncate dimensions
SELECT embedding[:768]::vector(768) FROM documents;
```

## Storage Estimation

```sql
-- Estimate table size
SELECT
    pg_size_pretty(pg_total_relation_size('documents')) AS total_size,
    pg_size_pretty(pg_relation_size('documents')) AS table_size,
    pg_size_pretty(pg_indexes_size('documents')) AS index_size;

-- Estimate per-row size
-- vector(1536): 4 * 1536 + overhead = ~6.1 KB
-- halfvec(3072): 2 * 3072 + overhead = ~6.1 KB
-- vector(3072): 4 * 3072 + overhead = ~12.3 KB
```
