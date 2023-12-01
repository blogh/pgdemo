CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j4.index_inutilisables;
CREATE TABLE j4.index_inutilisables(id int PRIMARY KEY, d date, t text);

INSERT INTO j4.index_inutilisables(id, d, t) 
  SELECT x, '2022-01-01'::date - INTERVAL '1 day' * x, 'numéro ' || x
    FROM generate_series(1, 10000) AS F(x);

CREATE INDEX ON j4.index_inutilisables(d);
CREATE INDEX ON j4.index_inutilisables(t COLLATE "fr_FR.utf8");
\prompt PAUSE
:cls

-- *** Exemples ***********************************************
-- Mauvais type
EXPLAIN (ANALYZE) SELECT * FROM j4.index_inutilisables WHERE id =  10::numeric;
\prompt PAUSE
:cls

-- Fonction sur une colonne
EXPLAIN (ANALYZE) SELECT * FROM j4.index_inutilisables WHERE to_char(d, 'YYYY') = '2023';
EXPLAIN (ANALYZE) SELECT * FROM j4.index_inutilisables WHERE d >= '2023-01-01' AND d < '2024-01-01';
\prompt PAUSE
:cls

-- LIKE et classes d'opérateurs
EXPLAIN (ANALYZE) SELECT * FROM j4.index_inutilisables WHERE t LIKE 'numéro 1%';

CREATE INDEX ON j4.index_inutilisables(t COLLATE "fr_FR.utf8" varchar_pattern_ops);

EXPLAIN (ANALYZE) SELECT * FROM j4.index_inutilisables WHERE t LIKE 'numéro 1%';
\prompt PAUSE
:cls

-- Index Invalides
SELECT indrelid::regclass, indexrelid::regclass, indisvalid
  FROM pg_index
 WHERE indrelid::regclass::text = 'j4.index_inutilisables';
\prompt PAUSE
:cls

