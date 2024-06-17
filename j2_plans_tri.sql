-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- Tri ---------------------------------------------------------------------
-- Tri en mémoire
EXPLAIN (ANALYZE) SELECT * FROM employes ORDER BY fonction;
\prompt PAUSE
-- Tri sur disque
EXPLAIN (ANALYZE) SELECT * FROM employes_big ORDER BY fonction;
\prompt PAUSE
-- utilisation d'un index
EXPLAIN SELECT * FROM employes_big ORDER BY matricule;
\prompt PAUSE
-- utilisation d'un index dans l'autre sens
EXPLAIN SELECT * FROM employes_big ORDER BY matricule DESC;
\prompt PAUSE
:cls

-- Quand un idx est il utilisable pr un tri ? --------------------------------
DROP TABLE IF exists t1;
CREATE TABLE t1 (c1 integer, c2 integer, c3 integer);
INSERT INTO t1 SELECT i, i+1, i+2 FROM generate_series(1, 10000000) AS i;
CREATE INDEX t1_c2_idx ON t1(c2);
VACUUM ANALYZE t1;

-- Utilisation de l'index
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2;
\prompt PAUSE
-- Pas d'index
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c1, c2;
\prompt PAUSE
-- incrémental sort (13+) (pas d'index avant)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2, c3;
\prompt PAUSE
-- incrémental sort et LIMIT (13+)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2, c3 LIMIT 10;
\prompt PAUSE
-- incrémental sort et DISTINCT (13+)
EXPLAIN (ANALYZE, BUFFERS) SELECT DISTINCT c2,c1,c3 FROM t1;
\prompt PAUSE
:cls


