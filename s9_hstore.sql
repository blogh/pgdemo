-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS s9; 
SET search_path TO s9, public;
DROP TABLE IF EXISTS animaux;
:cls

--*** Partitionnement déclaratif par listes *****************
CREATE EXTENSION hstore ;
--
CREATE TABLE animaux (nom text, caract hstore);
INSERT INTO animaux VALUES ('canari','pattes=>2,vole=>oui');
INSERT INTO animaux VALUES ('loup','pattes=>4,carnivore=>oui');
INSERT INTO animaux VALUES ('carpe','eau=>douce');
--
CREATE INDEX idx_animaux_donnees 
       ON animaux USING gist (caract);
CREATE INDEX idx_animaux_volant
       ON animaux USING btree ((caract->'vole'));
--
ANALYZE animaux;
\prompt PAUSE
:cls

--*** Utilisation *******************************************
-- Stockage
SELECT * FROM animaux;
\prompt PAUSE
:cls

--*** Accès *******************************************
SET enable_seqscan TO off; -- pour forcer des index scan quand c'est possible

-- Indexation BTREE 
-- -> non indexable
EXPLAIN (ANALYZE) SELECT *, caract -> 'vole' AS vole
  FROM animaux
 WHERE caract -> 'vole' = 'oui';
-- Résultat
SELECT *, caract -> 'vole' AS vole
  FROM animaux
 WHERE caract -> 'vole' = 'oui';
\prompt PAUSE
:cls

-- Indexation GIN
-- Accès : opérateurs -> et @>
-- -> non indexable
EXPLAIN (ANALYZE) SELECT *, caract -> 'pattes' AS nb_pattes
  FROM animaux
 WHERE caract -> 'carnivore' = 'oui';
-- @> (continent) ? (contient la clé) ?& (contient toutes les clés) ?| (contient certaines clés) indexables
EXPLAIN (ANALYZE) SELECT *, caract -> 'pattes' AS nb_pattes
  FROM animaux
 WHERE caract @> 'carnivore=>oui';
-- Résultat
SELECT *, caract -> 'pattes' AS nb_pattes
  FROM animaux
 WHERE caract @> 'carnivore=>oui';
\prompt PAUSE
:cls

-- exemple avec ?
EXPLAIN (ANALYZE) SELECT *
  FROM animaux
 WHERE caract ? 'vole';
-- Résultat
SELECT *
  FROM animaux
 WHERE caract ? 'vole';
\prompt PAUSE
:cls

-- each
SELECT a.nom, hs.*
  FROM s9.animaux AS a 
       LEFT OUTER JOIN LATERAL s9.each(a.caract) AS hs ON true;
\prompt PAUSE
:cls

--*** Mise a jour *******************************************
SELECT * FROM animaux WHERE nom = 'loup';
-- Ajout: hstore || hstore (concaténation)
UPDATE animaux SET caract = caract || 'poil=>t,mignon=>t'::hstore
 WHERE nom = 'loup';
-- Ajout
UPDATE animaux SET caract['bruyant'] = 'oui'
 WHERE nom = 'loup';
-- MAJ
UPDATE animaux SET caract['mignon'] = 'f'
 WHERE nom = 'loup';
--
SELECT * FROM animaux WHERE nom = 'loup';
\prompt PAUSE
:cls

--*** Supressions *******************************************
SELECT * FROM animaux WHERE nom = 'loup';
-- Supression par clé: hstore - text[] 
UPDATE animaux SET caract = caract - ARRAY['mignon']
 WHERE nom = 'loup';
-- Supression par clé valeur: hstore - hstore
UPDATE animaux SET caract = caract - 'carnivore=>non, bruyant=>oui, rapide=>absolument'::hstore
 WHERE nom = 'loup';
--
SELECT * FROM animaux WHERE nom = 'loup';
\prompt PAUSE
:cls

--*** Conversion *******************************************
-- tableau
SELECT hstore_to_matrix(caract) FROM animaux WHERE caract->'vole' = 'oui';
-- jsonb
SELECT caract::jsonb FROM animaux WHERE (caract->'pattes')::int = 2;

