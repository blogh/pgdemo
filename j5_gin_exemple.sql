CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j5.exp_gin;

CREATE TABLE j5.exp_gin (i int, a int[]) ;
INSERT INTO j5.exp_gin SELECT i, ARRAY[i, i+1] FROM generate_series(1,100000) i ;

\prompt PAUSE
:cls

-- *** Exemple ***********************************************
-- egalité entre tableaux
CREATE INDEX on j5.exp_gin USING BTREE(a);
EXPLAIN (COSTS OFF) SELECT * FROM j5.exp_gin WHERE a = ARRAY[42,43] ;
\prompt PAUSE
:cls

-- tableaux inclus dans
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM j5.exp_gin WHERE a @> ARRAY[42] ;
CREATE INDEX ON j5.exp_gin USING GIN(a);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM j5.exp_gin WHERE a @> ARRAY[42] ;
\prompt PAUSE
:cls

-- *** Autres exemples **************************************
-- présence d'une clé dans un document json
DROP TABLE IF EXISTS j5.exp_gin_json;

CREATE TABLE j5.exp_gin_json(json jsonb);
CREATE INDEX ON j5.exp_gin_json USING BTREE(json jsonb_ops);
INSERT INTO j5.exp_gin_json(json) SELECT ('{"b": "' || x || '", "c' || mod(x, 10) || '" : "cccc"}')::jsonb FROM generate_series(1, 10000) AS F(x);
\prompt PAUSE
:cls

EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json ? 'c1';
CREATE INDEX idx_exp_gin_json_json_gin ON j5.exp_gin_json USING GIN(json jsonb_ops);
CREATE INDEX idx_exp_gin_json_json_gin_pops ON j5.exp_gin_json USING GIN(json jsonb_path_ops);
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json ? 'c1';
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json ?| ARRAY['c1','c9']; -- contient 'c1' ou 'c9'
\prompt PAUSE
:cls

-- valeur d'un objet dans le document json avec un GIN
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json->>'b' = '15';
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json @> '{ "b": "15"}';
\prompt PAUSE
:cls

-- valeur d'un objet dans le document json avec un BTREE (supporte > >= = <= <)
CREATE INDEX idx_exp_gin_json_json_b_btree ON j5.exp_gin_json USING BTREE((json ->> 'b'));
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json->>'b' = '15';
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json->>'b' < '15';
\prompt PAUSE
:cls

-- valeur d'un objet dans le document json avec un HASH (supporte =)
CREATE INDEX idx_exp_gin_json_json_b_hash ON j5.exp_gin_json USING HASH((json ->> 'b'));
\di+ j5.idx_exp_gin_json_json*;
DROP INDEX j5.idx_exp_gin_json_json_b_btree;
\prompt PAUSE

EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json->>'b' = '15';
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_json WHERE json->>'b' < '15';
\prompt PAUSE
DROP INDEX j5.idx_exp_gin_json_json_b_hash;
:cls

-- LIKE %string% indexation avec pg_trgm
DROP TABLE IF EXISTS j5.exp_gin_trgm;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE TABLE j5.exp_gin_trgm(t text);
INSERT INTO j5.exp_gin_trgm(t) SELECT mod(x, 10) || 'Numéro ' || x || ' was called.' FROM generate_series(1, 10000) AS F(x);

EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_trgm WHERE t LIKE '% Numéro 10%';
CREATE INDEX ON j5.exp_gin_trgm USING GIN(t gin_trgm_ops);
EXPLAIN (ANALYZE) SELECT * FROM j5.exp_gin_trgm WHERE t LIKE '% Numéro 10%';
\prompt PAUSE
:cls

-- indexer des types scalaires avec l'extension btree_gin
DROP TABLE IF EXISTS j5.scalaires;

CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE TABLE j5.scalaires(i int, t text, b boolean);
INSERT INTO j5.scalaires(i, t, b) 
  SELECT mod(x, 100), 
         'numéro ' || x ,
	 CASE WHEN x % 3 = 0 THEN true
	      ELSE false
	 END
    FROM generate_series(1, 10000) AS F(x);

-- int
CREATE INDEX idx_scalaires_i_gin ON j5.scalaires USING GIN(i);
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE i = 100;
\prompt PAUSE

-- text
CREATE INDEX idx_scalaires_t_gin ON j5.scalaires USING GIN(t);
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE t = 'numéro 10'; 
\prompt PAUSE

-- booleen
CREATE INDEX idx_scalaires_b_gin ON j5.scalaires USING GIN(b);
CREATE INDEX idx_scalaires_b_btree ON j5.scalaires USING BTREE(b);
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE b;
\di+ j5.idx_scalaires_b_*
\prompt PAUSE

DROP INDEX j5.idx_scalaires_i_gin;
DROP INDEX j5.idx_scalaires_t_gin;
DROP INDEX j5.idx_scalaires_b_gin;
DROP INDEX j5.idx_scalaires_b_btree;
:cls

-- index multi colonne
CREATE INDEX ON j5.scalaires USING GIN (i, t, b);

EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE i = 100;
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE t = 'numéro 10'; 
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE b;
EXPLAIN (ANALYZE) SELECT * FROM j5.scalaires WHERE NOT b AND i > 200;

\prompt PAUSE
:cls
