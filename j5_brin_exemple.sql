CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j5.brin_demo;

CREATE TABLE j5.brin_demo (id int, age int);
SET work_mem TO '300MB' ;
INSERT INTO j5.brin_demo
   SELECT id, trunc(random() * 90 + 1)  AS age
     FROM   generate_series(1, 2e6) id
    ORDER  BY age ;

CREATE INDEX brin_demo_btree_idx ON j5.brin_demo USING btree (age);
CREATE INDEX brin_demo_brin_idx  ON j5.brin_demo USING brin (age);
CLUSTER j5.brin_demo USING brin_demo_btree_idx;
\di+ j5.brin_demo*
\prompt PAUSE
:cls

-- contenu de l'index
CREATE EXTENSION IF NOT EXISTS pageinspect ;
SELECT *
  FROM brin_page_items(get_raw_page('j5.brin_demo_brin_idx', 2),'j5.brin_demo_brin_idx') LIMIT 20;
\prompt PAUSE
:cls

DROP INDEX j5.brin_demo_btree_idx ;
SET enable_seqscan TO off;
SET max_parallel_workers_per_gather TO 0;
EXPLAIN (ANALYZE,BUFFERS,COSTS OFF) SELECT count(*) FROM j5.brin_demo WHERE age = 87 ;
\prompt PAUSE
:cls

-- contenu de l'index apres avoir créé du mouvement dans les lignes
UPDATE j5.brin_demo
   SET    age=age+0
 WHERE  random()>0.99 ;  -- environ 20000 lignes
VACUUM j5.brin_demo ;
UPDATE j5.brin_demo
   SET    age=age+0
 WHERE  age > 80 AND random()>0.90 ;  -- environ 22175 lignes

VACUUM ANALYZE j5.brin_demo ;
SELECT *
  FROM brin_page_items(get_raw_page('j5.brin_demo_brin_idx', 2),'j5.brin_demo_brin_idx') LIMIT 20;
\prompt PAUSE
:cls

EXPLAIN (ANALYZE,BUFFERS,COSTS OFF) SELECT count(*) FROM j5.brin_demo WHERE age = 87 ;
\prompt PAUSE
:cls

-- re-ordonner la table en fonction de l'index btree
CREATE INDEX brin_demo_btree_idx ON j5.brin_demo USING btree (age);
CLUSTER j5.brin_demo USING brin_demo_btree_idx;
SELECT *
  FROM brin_page_items(get_raw_page('j5.brin_demo_brin_idx', 2),'j5.brin_demo_brin_idx') LIMIT 20;
\prompt PAUSE
:cls
