CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

DROP TABLE IF EXISTS j5.demo_gist;
DROP TABLE IF EXISTS j5.demo_gin;
:cls
-- *** Création des tables ************************************
-- valeurs répétées
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOt EXISTS bloom;

CREATE TABLE j5.demo_gist (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;
CREATE TABLE j5.demo_gin  (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;
CREATE TABLE j5.demo_bloom  (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;

INSERT INTO j5.demo_gist
  SELECT n, mod(n,37) AS i, mod(n,53) AS j, mod (n, 97) AS k, mod(n,229) AS l
    FROM generate_series (1,1000000) n ;

INSERT INTO j5.demo_gin
  SELECT n, mod(n,37) AS i, mod(n,53) AS j, mod (n, 97) AS k, mod(n,229) AS l
   FROM generate_series (1,1000000) n ;

INSERT INTO j5.demo_bloom
  SELECT n, mod(n,37) AS i, mod(n,53) AS j, mod (n, 97) AS k, mod(n,229) AS l
   FROM generate_series (1,1000000) n ;

\timing on
CREATE INDEX demo_gist_idx ON j5.demo_gist USING gist (i,j,k,l) ;
CREATE INDEX demo_gin_idx ON j5.demo_gin USING gin (i,j,k,l) ;
CREATE INDEX demo_btree_idx ON j5.demo_gin USING btree (i,j,k,l) ;
CREATE INDEX demo_bloom_idx ON j5.demo_bloom USING bloom (i,j,k,l) ;
\timing off

\di+ j5.demo_*_idx

ANALYZE j5.demo_gin, j5.demo_gist, j5.demo_bloom;

\prompt PAUSE
DROP INDEX demo_btree_idx;
:cls

-- *** = ***********************************************
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_gist WHERE j=17 AND l=17 ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_gin WHERE j=17 AND l=17  ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_bloom WHERE j=17 AND l=17  ;

\prompt PAUSE
:cls

-- *** BETWEEN ***********************************************
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_gist
WHERE j BETWEEN 17 AND 21 AND l BETWEEN 17 AND 21  ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_gin
WHERE j BETWEEN 17 AND 21 AND l BETWEEN 17 AND 21  ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM j5.demo_bloom
WHERE j BETWEEN 17 AND 21 AND l BETWEEN 17 AND 21  ;

\prompt PAUSE
:cls

-- *** Index only scan ***********************************************
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT j,l FROM j5.demo_gist WHERE j=17 AND l=17 ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT j,l FROM j5.demo_gin WHERE j=17 AND l=17 ;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT j,l FROM j5.demo_bloom WHERE j=17 AND l=17 ;

\prompt PAUSE
DROP TABLE j5.demo_gist;
DROP TABLE j5.demo_gin;
DROP TABLE j5.demo_bloom;
:cls


-- *** Création des tables ************************************
-- valeurs distinctes
CREATE TABLE j5.demo_gist (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;
CREATE TABLE j5.demo_gin  (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;
CREATE TABLE j5.demo_bloom  (n int, i int, j int, k int, l int,
                        filler char(50) default ' ') ;

INSERT INTO j5.demo_gin
  SELECT n, n AS i, 100e6+n AS j, 200e6+n AS k, 300e6+n AS l
  FROM generate_series (1,1000000) n ;

INSERT INTO j5.demo_gist
  SELECT n, n AS i, 100e6+n AS j, 200e6+n AS k, 300e6+n AS l
  FROM generate_series (1,1000000) n ;

INSERT INTO j5.demo_bloom
  SELECT n, mod(n,37) AS i, mod(n,53) AS j, mod (n, 97) AS k, mod(n,229) AS l
   FROM generate_series (1,1000000) n ;

\timing on
CREATE INDEX demo_gist_idx ON j5.demo_gist USING gist (i,j,k,l) ;
CREATE INDEX demo_gin_idx ON j5.demo_gin USING gin (i,j,k,l) ;
CREATE INDEX demo_btree_idx ON j5.demo_gin USING btree (i,j,k,l) ;
CREATE INDEX demo_bloom_idx ON j5.demo_bloom USING bloom (i,j,k,l) ;
\timing off

\di+ j5.demo_*_idx

ANALYZE j5.demo_gin, j5.demo_gist;

-- *** Index only scan ***********************************************

\prompt PAUSE
:cls

