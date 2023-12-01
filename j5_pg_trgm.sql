CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j5.test_trgm;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE j5.test_trgm (text_data text);

INSERT INTO j5.test_trgm(text_data)
VALUES ('hello'), ('hello everybody'), ('helo young man'),('hallo!'),('HELLO !');
INSERT INTO j5.test_trgm SELECT 'hola' FROM generate_series(1,1000);

CREATE INDEX ON j5.test_trgm USING gist (text_data gist_trgm_ops);

\prompt PAUSE
:cls

-- *** Exemple ***********************************************
-- principe
SELECT show_trgm('hello');
\prompt PAUSE
:cls

EXPLAIN (ANALYZE)
SELECT text_data FROM j5.test_trgm
WHERE  text_data like '%hello%' ;
\prompt PAUSE
:cls

EXPLAIN (ANALYZE) SELECT text_data, text_data <-> 'hello' AS distance
 FROM j5.test_trgm
 ORDER BY distance
 LIMIT 4;

SELECT text_data, text_data <-> 'hello' AS distance
 FROM j5.test_trgm
 ORDER BY distance
 LIMIT 4;
\prompt PAUSE
