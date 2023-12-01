CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (c1 int, c2 int, c3 int, c4 text);

-- insert de 1000000 lignes
INSERT INTO t1 (c1, c2, c3, c4)
SELECT i*10,j*5,k*20, 'text'||i||j||k
FROM generate_series (1,100) i
CROSS JOIN generate_series(1,100) j
CROSS JOIN generate_series(1,100) k ;

CREATE INDEX ON t1 (c1, c2, c3) ;

VACUUM ANALYZE t1 ;

\prompt PAUSE
:cls

-- *** Accès aux données **************************************
-- Figer des paramètres pour l'exemple
SET max_parallel_workers_per_gather to 0;
SET seq_page_cost TO 1 ;
SET random_page_cost TO 4 ;

-- Prédicats sur les premiers colonnes de l'index
EXPLAIN SELECT * FROM t1 WHERE c1 = 1000 and c2=500 and c3=2000 ;
EXPLAIN SELECT c1,c2,c3 FROM t1 WHERE c1 = 1000 and c2=500 ;
\prompt PAUSE
:cls

-- Prédicats sur d'autres colonnes
SET random_page_cost TO 0.1 ; SET seq_page_cost TO 0.1 ;  -- SSD
EXPLAIN (ANALYZE,BUFFERS) SELECT * FROM t1 WHERE c3 = 2000 ;

SET random_page_cost TO 4 ; SET seq_page_cost TO 1 ;  -- défaut (disque mécanique)
EXPLAIN (ANALYZE,BUFFERS) SELECT * FROM t1 WHERE c3 = 2000 ;
\prompt PAUSE
:cls

-- Prédicats différents de < sur les premiers colonnes
EXPLAIN (ANALYZE) SELECT * FROM t1 WHERE c1 = 100 AND c2 >= 80 AND c3 = 40 ;
\prompt PAUSE
:cls

-- *** Tris ***************************************************
EXPLAIN (ANALYZE) SELECT * FROM t1 ORDER BY c1 ;
EXPLAIN (ANALYZE) SELECT * FROM t1 ORDER BY c1, c2 ;
EXPLAIN (ANALYZE) SELECT * FROM t1 ORDER BY c1, c2, c3 ;
EXPLAIN (ANALYZE) SELECT * FROM t1 ORDER BY c1, c2, c4 ;
EXPLAIN (ANALYZE) SELECT * FROM t1 ORDER BY c2 ;
\prompt PAUSE
