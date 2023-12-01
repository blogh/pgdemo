CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j4.index_fonctions;
CREATE TABLE j4.index_fonctions(id int PRIMARY KEY, d date, t timestamp with time zone);

INSERT INTO j4.index_fonctions(id, d, t) 
  SELECT x, '2022-01-01'::date - INTERVAL '1 day' * x, '2022-01-01'::date - INTERVAL '1 day' * x
    FROM generate_series(1, 10000) AS F(x);

CREATE INDEX ON j4.index_fonctions(d);
CREATE INDEX ON j4.index_fonctions(t);

\prompt PAUSE
:cls

-- *** Exemple ***********************************************
-- to_char n'est pas immutable
EXPLAIN (ANALYZE) SELECT * FROM j4.index_fonctions WHERE to_char(d, 'YYYY') = '2023';
CREATE INDEX ON j4.index_fonctions(to_char(d, 'YYYY'));
\prompt PAUSE
:cls

-- extract pourrait marcher mais ...
EXPLAIN (ANALYZE) SELECT * FROM j4.index_fonctions WHERE extract('year' FROM d) = 2023;
CREATE INDEX ON j4.index_fonctions(extract('year' FROM d));
ANALYZE j4.index_fonctions;
EXPLAIN (ANALYZE) SELECT * FROM j4.index_fonctions WHERE extract('year' FROM d) = 2023;
\prompt PAUSE

SELECT * FROM pg_stats WHERE schemaname = 'j4' AND tablename = 'index_fonctions_extract_idx' \gx
\prompt PAUSE
:cls

-- si la colonne est un timestamp with timezone on ne peut pas indexer
EXPLAIN (ANALYZE) SELECT * FROM j4.index_fonctions WHERE extract('year' FROM t) = 2023;
CREATE INDEX ON j4.index_fonctions(extract('year' FROM t));
\pset pager off
\df+ pg_catalog.extract
\prompt PAUSE

CREATE OR REPLACE FUNCTION annee_fr(t timestamp with time zone )
  RETURNS int
  AS $$
	SELECT extract('year' from(t AT TIME ZONE 'Europe/Paris')::timestamp with time zone);
  $$ 
  LANGUAGE sql 
  IMMUTABLE;

CREATE INDEX ON j4.index_fonctions(annee_fr(t));
ANALYZE j4.index_fonctions;
EXPLAIN (ANALYZE) SELECT * FROM j4.index_fonctions WHERE annee_fr(t) = 2023;

\prompt PAUSE
:cls

-- fonction et inlining
DROP TABLE IF EXISTS produits CASCADE;
CREATE TABLE produits(id int PRIMARY KEY, longueur int, largeur int, hauteur int);
INSERT INTO produits 
  SELECT x, random() * 5, random() * 3, random() * 7
    FROM generate_series(1,100000) AS F(x);
\prompt PAUSE
:cls

-- plpgsql: boite noire
CREATE OR REPLACE function volume_plpgsql(p produits) RETURNS int
AS $$
BEGIN
  RETURN p.longueur * p.hauteur * p.largeur;
END
$$ language plpgsql
IMMUTABLE;

CREATE INDEX ON produits(volume_plpgsql(produits));

EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE volume_plpgsql(p) > 10;
\prompt PAUSE
:cls

-- sql: inline
CREATE OR REPLACE function volume_sql(p produits) RETURNS int
AS $$
 SELECT p.longueur * p.hauteur * p.largeur;
$$ language SQL
IMMUTABLE ;

CREATE INDEX idx_produits_volume_sql ON produits(volume_sql(produits));

EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE volume_sql(p) > 10;
EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE (longueur * hauteur * largeur) > 10;

DROP INDEX idx_produits_volume_sql;
CREATE INDEX ON produits((longueur * hauteur * largeur));

EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE volume_sql(p) > 10;
EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE (longueur * hauteur * largeur) > 10;
EXPLAIN (ANALYZE) SELECT id FROM produits AS p WHERE (longueur * largeur * hauteur) > 10;
\prompt PAUSE
:cls


