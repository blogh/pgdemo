DROP DATABASE IF EXISTS j4_utf8;
CREATE DATABASE j4_utf8 ENCODING "utf8" LOCALE "fr_FR.utf8" TEMPLATE template0;
\c j4_utf8
CREATE SCHEMA IF NOT EXISTS j4;

\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
\c j4_utf8
DROP TABLE IF EXISTS j4.classes_operateurs;
CREATE TABLE j4.classes_operateurs(id int PRIMARY KEY, t text);

INSERT INTO j4.classes_operateurs(id, t) 
  SELECT x, 'numéro ' || x
    FROM generate_series(1, 10000) AS F(x);

\l+
\prompt PAUSE
:cls

-- *** Classes d'opérateurs **********************************
-- Différents tri en fonction de la collation
SELECT * FROM (VALUES ('a'),('A'),('â'),('à')) AS F(x) ORDER BY x COLLATE "fr_FR.utf8";
SELECT * FROM (VALUES ('a'),('A'),('â'),('à')) AS F(x) ORDER BY x COLLATE "da_DK.utf8";
SELECT * FROM (VALUES ('a'),('A'),('â'),('à')) AS F(x) ORDER BY x COLLATE "C";
\prompt PAUSE
:cls

-- Exemple avec la collation C
CREATE INDEX idx_classes_operateurs_t_collate_c ON j4.classes_operateurs(t COLLATE "C");
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs WHERE t LIKE 'numéro 1%';
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs ORDER BY t;
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs ORDER BY t COLLATE "C";
DROP INDEX j4.idx_classes_operateurs_t_collate_c;
-- /!\ Comment réécrire le LIKE de façon fiable alors que la COLLATION change l'ordre des caractères ?
\prompt PAUSE
:cls

-- Exemple avec une collation fr_FR.utf8
CREATE INDEX idx_classes_operateurs_t ON j4.classes_operateurs(t);
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs WHERE t LIKE 'numéro 1%';
DROP INDEX j4.idx_classes_operateurs_t;
\prompt PAUSE
:cls

-- varchar_pattern_ops ou text_pattern_ops forcent une comparaison octale
CREATE INDEX ON j4.classes_operateurs(t varchar_pattern_ops);
-- Notez que l'opérateur est différent (~>=~ au lieu de >= et ~<~ au lieu de <)
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs WHERE t LIKE 'numéro 1%';
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs WHERE t LIKE '%numéro 1%';
\prompt PAUSE
:cls

-- Attention les _pattern_ops ne supportent pas < <= > >=
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs ORDER BY t LIMIT 10;
CREATE INDEX ON j4.classes_operateurs(t);
EXPLAIN (ANALYZE) SELECT * FROM j4.classes_operateurs ORDER BY t LIMIT 10;
\prompt PAUSE
