-- prefix_tsquery(config, text [, join]): a tsquery that prefix-matches every
-- term, for inflected languages (Finnish, Estonian, Hungarian, Turkish...)
-- indexed with the 'simple' config. websearch_to_tsquery cannot emit :*.
--
--   'verkko-opetus kirjasto'
--     -> ('verkko-opetus':* | 'verkko':* | 'opetus':*) | 'kirjasto':*
--
-- Why it looks like this (each case returns zero rows, not an error):
-- * Terms are OR-joined: one term missing an inflected form (consonant
--   gradation: hakemus / hakemuksesta) would sink an AND of all of them.
--   ts_rank_cd still ranks rows matching more terms first.
-- * A hyphenated token is expanded into an OR group. Passed through as-is,
--   to_tsquery turns it into a phrase that never matches an inflected form.
-- * tsquery operators and punctuation are stripped, so raw user input cannot
--   raise a syntax error.
-- * Tokens shorter than 3 characters are dropped from OR queries unless nothing
--   longer remains, so "EU" alone still works.
-- * Input with a double quote goes to websearch_to_tsquery for phrase search.

CREATE OR REPLACE FUNCTION prefix_tsquery(
    p_config regconfig,
    p_text   TEXT,
    p_join   TEXT              -- 'auto' | 'or' | 'and'; 'and' is for ablations
)
RETURNS tsquery
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
    MIN_OR_TERM_LENGTH CONSTANT INT := 3;
    v_token   TEXT;
    v_cleaned TEXT;
    v_parts   TEXT[];
    v_arms    TEXT[];
    v_terms   TEXT[] := ARRAY[]::TEXT[];
    v_weights INT[]  := ARRAY[]::INT[];
    v_kept    TEXT[];
    v_join    TEXT;
BEGIN
    IF p_text LIKE '%"%' THEN
        RETURN websearch_to_tsquery(p_config, p_text);
    END IF;

    FOREACH v_token IN ARRAY regexp_split_to_array(trim(p_text), '\s+') LOOP
        v_cleaned := regexp_replace(v_token, '[''"()!&|<>:?\\*]', '', 'g');
        v_cleaned := regexp_replace(v_cleaned, '^[^[:alnum:]]+|[^[:alnum:]]+$', '', 'g');
        CONTINUE WHEN v_cleaned = '';

        v_parts := ARRAY(
            SELECT p FROM regexp_split_to_table(v_cleaned, '[^[:alnum:]]+') AS p
            WHERE p <> ''
        );
        CONTINUE WHEN array_length(v_parts, 1) IS NULL;

        IF array_length(v_parts, 1) = 1 THEN
            v_arms := v_parts;
        ELSE
            -- Compound first (most specific), then each part, first-seen order.
            v_arms := ARRAY(
                SELECT a FROM (
                    SELECT u.a, min(u.ord) AS ord
                    FROM unnest(ARRAY[v_cleaned] || v_parts) WITH ORDINALITY AS u(a, ord)
                    GROUP BY u.a
                ) s
                ORDER BY s.ord
            );
        END IF;

        IF array_length(v_arms, 1) = 1 THEN
            v_terms := v_terms || (quote_literal(v_arms[1]) || ':*');
        ELSE
            v_terms := v_terms || (
                '(' || array_to_string(
                    ARRAY(SELECT quote_literal(a) || ':*' FROM unnest(v_arms) AS a),
                    ' | ') || ')'
            );
        END IF;

        v_weights := v_weights || (SELECT max(length(a))::INT FROM unnest(v_arms) AS a);
    END LOOP;

    IF array_length(v_terms, 1) IS NULL THEN
        RETURN NULL;
    END IF;

    IF array_length(v_terms, 1) = 1 THEN
        v_join := 'and';
    ELSIF p_join = 'auto' THEN
        v_join := 'or';
    ELSE
        v_join := p_join;
    END IF;

    IF v_join = 'or' THEN
        v_kept := ARRAY(
            SELECT u.t FROM unnest(v_terms, v_weights) AS u(t, w)
            WHERE u.w >= MIN_OR_TERM_LENGTH
        );
        IF array_length(v_kept, 1) IS NULL THEN
            v_kept := v_terms;
        END IF;
    ELSE
        v_kept := v_terms;
    END IF;

    RETURN to_tsquery(
        p_config,
        array_to_string(v_kept, CASE WHEN v_join = 'or' THEN ' | ' ELSE ' & ' END)
    );
END;
$$;

-- A two-argument wrapper, not DEFAULT 'auto' on p_join: a database that already
-- has a two-argument prefix_tsquery would then hold two candidates, and every
-- existing call would fail with "function prefix_tsquery(unknown, unknown) is
-- not unique".
CREATE OR REPLACE FUNCTION prefix_tsquery(p_config regconfig, p_text TEXT)
RETURNS tsquery LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT prefix_tsquery(p_config, p_text, 'auto') $$;

/*
SELECT id FROM documents
WHERE to_tsvector('simple', content) @@ prefix_tsquery('simple', 'kirjasto opetus')
ORDER BY ts_rank_cd(to_tsvector('simple', content), prefix_tsquery('simple', 'kirjasto opetus')) DESC;
*/
