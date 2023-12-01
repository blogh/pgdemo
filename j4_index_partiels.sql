CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j4.index_partiels;
CREATE TABLE j4.index_partiels(id int PRIMARY KEY, traite boolean, type text, z int);

INSERT INTO j4.index_partiels
  SELECT x, true,
         CASE WHEN x % 3 = 0 THEN 'FACTURATION'
              WHEN x % 3 = 1 THEN 'EXPEDITION'
	      ELSE 'COMMANDES'
	 END,
	 x
    FROM generate_series(1, 100000) AS F(x)
  UNION ALL
  SELECT x, false,
         CASE WHEN x % 3 = 0 THEN 'FACTURATION'
              WHEN x % 3 = 1 THEN 'EXPEDITION'
	      ELSE 'COMMANDES'
	 END,
	 x
    FROM generate_series(100001, 100010) AS F(x);

VACUUM ANALYZE j4.index_partiels;
\prompt PAUSE
:cls

-- *** Exemples **********************************************
-- sans index partiel
CREATE INDEX idx_index_partiels_type ON j4.index_partiels(type);
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'FACTURATION' AND NOT traite;
\prompt PAUSE

-- avec index partiel
CREATE INDEX idx_index_partiels_type_part ON j4.index_partiels(type) WHERE NOT traite;
\di+ j4.*index_partiels*
DROP INDEX j4.idx_index_partiels_type;
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'FACTURATION' AND NOT traite;
\prompt PAUSE
-- fonctionne aussi avec taite = false au lieu de NOT traite
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'FACTURATION' AND traite = false;
\prompt PAUSE
:cls

-- index partiel inutilisable si prédicat traite au lieu de NOT traité
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'FACTURATION' AND traite;
-- index partiel inutilisable si prédicat traite IS FALSE au lieu de NOT traite
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'FACTURATION' AND traite IS false;
SELECT NULL = false AS "NULL = FALSE", NULL IS FALSE AS "NULL IS FALSE";

\prompt PAUSE
DROP INDEX j4.idx_index_partiels_type_part;
:cls

-- index partiels avec IN
SET enable_seqscan TO off;
CREATE INDEX idx_index_partiels_type_part ON j4.index_partiels(type) WHERE type IN ('COMMANDES', 'FACTURATION');
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'COMMANDES';
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type IN ('COMMANDES', 'FACTURATION');
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'EXPEDITIONS';
\prompt PAUSE
DROP INDEX j4.idx_index_partiels_type_part;
:cls

-- index partiels avec NOT IN
CREATE INDEX idx_index_partiels_type_part ON j4.index_partiels(type) WHERE type NOT IN ('EXPEDITIONS');
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'COMMANDES';
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type IN ('COMMANDES', 'FACTURATION');
EXPLAIN (ANALYZE) SELECT * FROM j4.index_partiels WHERE type = 'EXPEDITIONS';
\prompt PAUSE
DROP INDEX j4.idx_index_partiels_type_part;
:cls

-- index partiels avec <
CREATE INDEX idx_index_partiels_z_part ON j4.index_partiels(type) WHERE z < 100;
EXPLAIN (ANALYZE) SELECT type FROM j4.index_partiels WHERE z < 10;
EXPLAIN (ANALYZE) SELECT type FROM j4.index_partiels WHERE z < 100;
EXPLAIN (ANALYZE) SELECT type FROM j4.index_partiels WHERE z < 1000;
EXPLAIN (ANALYZE) SELECT type FROM j4.index_partiels WHERE z = 5;
EXPLAIN (ANALYZE) SELECT type FROM j4.index_partiels WHERE z > 5;


