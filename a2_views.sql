-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS a2;
SET search_path TO a2, public;
DROP VIEW IF EXISTS capitaines_anon;
DROP MATERIALIZED VIEW IF EXISTS capitaines_anon;
DROP TABLE IF EXISTS capitaines;
DROP ROLE IF EXISTS guillaume;
:cls

-- vues ---------------------------------------------------

-- création de l'utilisateur guillaume
-- il n'aura pas accès à la table capitaines
-- par contre, il aura accès à la vue capitaines_anon
CREATE ROLE guillaume LOGIN;
ALTER ROLE guillaume SET search_path TO a2, public;
--
-- Table capitaines
CREATE TABLE capitaines (id serial, nom text, age integer, num_cartecredit text);
INSERT INTO capitaines (nom, age, num_cartecredit)
  VALUES ('Robert Surcouf', 20, '1234567890123456');
--
-- Création de la vue
CREATE VIEW capitaines_anon AS
  SELECT nom, age, substring(num_cartecredit, 0, 10) || '******' AS num_cc_anon
  FROM capitaines;
--
-- ajout du droit de lecture à l'utilisateur guillaume
GRANT USAGE ON SCHEMA a2 TO guillaume;
GRANT SELECT ON TABLE capitaines_anon TO guillaume;
\prompt PAUSE
:cls

-- 
SET ROLE TO guillaume;
--
-- vérification qu'on lit bien la vue mais pas la table
SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
SELECT * FROM capitaines;
\prompt PAUSE
:cls

--
SET ROLE postgres;

-- Modification de la table possible si elle ne touche pas la vue
ALTER TABLE capitaines ADD COLUMN unecolonne text;
--
ALTER TABLE capitaines DROP COLUMN age;
--
ALTER TABLE capitaines ALTER COLUMN age SET DATA TYPE numeric;
\prompt PAUSE
:cls

-- Modification de la vue pour ajouter une autre colonne calculée
CREATE OR REPLACE VIEW capitaines_anon AS SELECT
  nom,age,substring(num_cartecredit,0,10)||'******' AS num_cc_anon,
  md5(substring(num_cartecredit,0,10)) AS num_md5_cc
  FROM capitaines;
-- Résultat visible directement
SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
-- Vue modifiable
UPDATE capitaines_anon SET nom = 'Nicolas Surcouf' WHERE nom = 'Robert Surcouf';
SELECT * from capitaines_anon WHERE nom LIKE '%Surcouf';
-- Pas possible de mettre a jour une colonne calculée par la vue
UPDATE capitaines_anon SET num_cc_anon = '123456789xxxxxx'
  WHERE nom = 'Nicolas Surcouf';

--
EXPLAIN SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
\prompt PAUSE
:cls


-- vues materialisées ---------------------------------------------------

DROP VIEW capitaines_anon;
--
CREATE MATERIALIZED VIEW capitaines_anon AS
  SELECT nom,
    age,
    substring(num_cartecredit, 0, 10) || '******' AS num_cc_anon
  FROM capitaines;
--
-- Les données sont bien dans la vue matérialisée
SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
\prompt PAUSE
:cls

-- Mise à jour d'une ligne de la table
UPDATE capitaines SET nom = 'Robert Surcouf' WHERE nom = 'Nicolas Surcouf';
SELECT * FROM capitaines WHERE nom LIKE '%Surcouf';
SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
\prompt PAUSE

-- Explication: Refresh
EXPLAIN SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
--
REFRESH MATERIALIZED VIEW capitaines_anon;
--
SELECT * FROM capitaines_anon WHERE nom LIKE '%Surcouf';
\prompt PAUSE
:cls

-- Refresh concurrently
REFRESH MATERIALIZED VIEW CONCURRENTLY capitaines_anon;
--
CREATE UNIQUE INDEX ON capitaines_anon(nom);
--
REFRESH MATERIALIZED VIEW CONCURRENTLY capitaines_anon;
\prompt PAUSE

:cls
DROP TABLE IF EXISTS capitaines;
DROP MATERIALIZED VIEW IF EXISTS capitaines_anon;
DROP ROLE IF EXISTS guillaume;
:cls
