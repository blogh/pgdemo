CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls

-- *** Création des tables ************************************
DROP TABLE IF EXISTS j4.exp_parcours;
CREATE TABLE j4.exp_parcours(i int PRIMARY KEY, j int, t text);

INSERT INTO j4.exp_parcours(i, j, t)
 SELECT x, (random()*1000)::int, 'ligne ' || x 
   FROM generate_series(1, 10000) AS F(x);

CREATE INDEX ON j4.exp_parcours(j);

ANALYZE j4.exp_parcours;
\prompt PAUSE 
:cls

-- *** Exemples de parcours ***********************************
-- Index scan pour ramener une valeur
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours WHERE i = 100;
\prompt PAUSE 
-- Index scan pour ramener plusieurs valeurs 
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours WHERE i < 10 ORDER BY j; 
\prompt PAUSE 
-- Index scan pour trier dans l'ordre de l'index
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours WHERE i > 100 ORDER BY j; 
\prompt PAUSE 
-- Index scan pour trier dans l'ordre inverse de l'index
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours WHERE i > 100 ORDER BY j DESC; 
\prompt PAUSE 
-- Index scan pour ramener plusieurs valeurs avec une bitmap
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours WHERE j between 100 AND 500;
-- Index scan pour incremental sort
EXPLAIN (ANALYZE) SELECT * FROM j4.exp_parcours ORDER BY j, t;
\prompt PAUSE 

