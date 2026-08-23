# Vector Types and Dimensions

## Contents

- [Vector Types in pgvector](#vector-types-in-pgvector) — `vector`, `halfvec`, `bit`
- [Picking the column type from dimensions](#picking-the-column-type-from-dimensions)
- [Dimension Truncation](#dimension-truncation)
- [Choosing Vector Type](#choosing-vector-type)
- [Conversion Examples](#conversion-examples)
- [Storage Estimation](#storage-estimation)

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
- Storage: up to 16,000 dims; HNSW/IVFFlat indexing: up to 2,000 dims

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

Binary vectors for binary quantization. Pgvector 0.7.0+.

```sql
embedding bit(3072)

-- Index
CREATE INDEX ON documents USING hnsw (embedding bit_hamming_ops);
```

**Properties:**
- 1 bit per dimension
- Max dimensions: 64,000
- Use for extreme compression

## Picking the column type from dimensions

Choose by dimension count, not by vendor — look up your model's dimensions in
the provider's docs, then:

| Dimensions N | Column type | Why |
|---|---|---|
| N ≤ 2000 | `vector(N)` | Within HNSW/IVFFlat's native limit |
| 2000 < N ≤ 4000 | `halfvec(N)` (or `vector(N)` cast to halfvec at index time) | halfvec extends the index limit to 4000 |
| N > 4000 | `vector(N)` unindexed, or binary quantization (`bit`, up to 64,000) | No half-precision path |

1536 and 3072 are the dimensions you will meet most often, but several providers
ship 768, 1024, and configurable sizes.

## Dimension Truncation

Several providers (OpenAI's text-embedding-3 family, Cohere, Voyage among them)
support Matryoshka-style truncation: request fewer dimensions at the API level
and get a shorter vector that keeps most of the quality. Check whether yours
does before truncating — a naive `subvector()` on a model *not* trained for it
degrades recall badly.

```sql
-- SQL-side truncation. Only valid for Matryoshka-trained models; re-normalize
-- afterwards if you use cosine distance.
SELECT subvector(embedding, 1, 1536)::vector(1536) FROM documents;
```

**Trade-off:** fewer dimensions means less memory and faster distance
computation at some recall cost. The cost is model-specific — measure it on
your own eval set ([evaluation.md](evaluation.md)) rather than assuming it.

## Choosing Vector Type

### Use `vector(N)` (N ≤ 2000) when:
- Embedding fits in HNSW's native dimension limit
- Storage is not a concern
- Need maximum compatibility

### Use `halfvec(N)` (N ≤ 4000) when:
- Embedding exceeds vector's HNSW limit (2000), or
- You want ~50% memory savings at negligible precision cost
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
SELECT subvector(embedding, 1, 768)::vector(768) FROM documents;
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
