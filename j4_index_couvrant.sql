CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j4.index_couvrants;
CREATE TABLE j4.index_couvrants(id int PRIMARY KEY, note int, nom text);

INSERT INTO j4.index_couvrants
  SELECT x, (random()*12+8)::int, 'nom ' || mod(x,100)
    FROM generate_series(1, 100000) AS F(x);

VACUUM ANALYZE j4.index_couvrants;

SELECT schemaname, tablename, attname, n_distinct, 10000
 FROM pg_stats
WHERE schemaname = 'j4'
 AND  tablename = 'index_couvrants'
 AND  attname IN('id','note');

\prompt PAUSE
:cls
-- *** Acces index only **************************************
-- index scan vs index only scan
EXPLAIN (ANALYZE, BUFFERS) SELECT id FROM (SELECT generate_series(1, 500)) AS F(x) INNER JOIN j4.index_couvrants ON x = id;
--
EXPLAIN (ANALYZE, BUFFERS) SELECT id, nom FROM (SELECT generate_series(1, 500)) AS F(x) INNER JOIN j4.index_couvrants ON x = id;
\prompt PAUSE
-- augmentons encore: index only scan vs index scan vs seq scan
EXPLAIN (ANALYZE, BUFFERS) SELECT id FROM (SELECT generate_series(1, 1000)) AS F(x) INNER JOIN j4.index_couvrants ON x = id;
--
SET enable_seqscan TO off;
EXPLAIN (ANALYZE, BUFFERS) SELECT id, nom FROM (SELECT generate_series(1, 1000)) AS F(x) INNER JOIN j4.index_couvrants ON x = id;
RESET enable_seqscan;
--
EXPLAIN (ANALYZE, BUFFERS) SELECT id, nom FROM (SELECT generate_series(1, 1000)) AS F(x) INNER JOIN j4.index_couvrants ON x = id;
\prompt PAUSE
:cls

-- *** Impact sur le plan ************************************
EXPLAIN SELECT nom FROM j4.index_couvrants WHERE id IN (10,500,1000);
CREATE INDEX index_couvrants_id_nom_couvrant_idx ON j4.index_couvrants(id) INCLUDE(nom);
EXPLAIN (ANALYZE, BUFFERS) SELECT nom FROM j4.index_couvrants WHERE id IN (10,500,1000);
--EXPLAIN (ANALYZE, BUFFERS) SELECT nom FROM j4.index_couvrants WHERE id IN (10,500,1000) AND nom = 'nom 10';
\prompt PAUSE
:cls

-- *** Impact sur la taille **********************************
\di+ j4.*index_couvrants*
\prompt PAUSE

CREATE INDEX ON j4.index_couvrants(note);
CREATE INDEX ON j4.index_couvrants(note, nom);
CREATE INDEX index_couvrants_note_nom_couvrant_idx ON j4.index_couvrants(note) INCLUDE(nom);

\di+ j4.*index_couvrants_note*
\prompt PAUSE

