CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Indexation multicolonnes *****************************
CREATE EXTENSION IF NOT EXISTS btree_gist ;
DROP TABLE IF EXISTS demo_gist;
CREATE TABLE demo_gist AS

SELECT n, mod(n,37) AS i,mod(n,53) AS j, mod (n, 97) AS k, mod(n,229) AS l
FROM generate_series (1,10000) n ;

CREATE INDEX ON demo_gist USING gist (i,j,k,l);
VACUUM ANALYZE demo_gist ;
\prompt PAUSE
:cls

-- *** Exemple ***********************************************
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM demo_gist WHERE i=17 ;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM demo_gist WHERE j=50 ;
\prompt PAUSE
:cls

-- *** Géométrie & KNN (K plus proche voisins ****************
DROP TABLE IF EXISTS mes_points;
CREATE TABLE mes_points (p point);

INSERT INTO mes_points (SELECT point(i, j)
FROM generate_series(1, 100) i, generate_series(1,100) j WHERE random() > 0.8);

CREATE INDEX ON mes_points USING gist (p);

EXPLAIN (ANALYZE) SELECT p,
       p <-> point(18,36)
FROM   mes_points
ORDER BY p <-> point(18, 36)
LIMIT 4;
\prompt PAUSE
:cls

-- *** Contraintes d'exclusion ******************************
DROP TABLE IF EXISTS reservation;
CREATE TABLE reservation
(
  salle      TEXT,
  professeur TEXT,
  durant     tstzrange);

CREATE EXTENSION btree_gist ;

ALTER TABLE reservation ADD CONSTRAINT test_exclude EXCLUDE
USING gist (salle WITH =,durant WITH &&);

INSERT INTO reservation (professeur,salle,durant) VALUES
( 'marc', 'salle techno', '[2010-06-16 09:00:00, 2010-06-16 10:00:00)');
INSERT INTO reservation (professeur,salle,durant) VALUES
( 'jean', 'salle techno', '[2010-06-16 10:00:00, 2010-06-16 11:00:00)');
INSERT INTO reservation (professeur,salle,durant) VALUES
( 'jean', 'salle informatique', '[2010-06-16 10:00:00, 2010-06-16 11:00:00)');
INSERT INTO reservation (professeur,salle,durant) VALUES
( 'michel', 'salle techno', '[2010-06-16 10:30:00, 2010-06-16 11:00:00)');
\prompt PAUSE

