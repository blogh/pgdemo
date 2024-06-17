-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS t1; 
SET search_path TO t1, public;
DROP TABLE IF EXISTS fts;
DROP TEXT SEARCH CONFIGURATION myTS;
:cls

--*** FTS  *************************************************************
-- Configuration
CREATE TEXT SEARCH CONFIGURATION  myTS (COPY= FRENCH);
--
CREATE EXTENSION IF NOT EXISTS unaccent ;
\dx+ unaccent
--
ALTER TEXT SEARCH CONFIGURATION myTS 
      ALTER MAPPING FOR hword, hword_part, word 
                    WITH unaccent, french_stem;
--
\dF+ myTs
\prompt PAUSE
:cls

-- Conversion text tsvector
SELECT to_tsvector('french', 'Les champs sont plein de blé, cela attire les oiseaux');
--
SELECT to_tsvector('myTS', 'Les champs sont plein de blé, cela attire les oiseaux');
\prompt PAUSE
:cls


-- Création d'une question
SELECT to_tsquery('myTs', 'ble & oiseau');
--
SELECT phraseto_tsquery('myTS', 'cela attire des oiseaux');
--
SELECT plainto_tsquery('myTS', 'cela attire des oiseaux');
--
SELECT websearch_to_tsquery('myTS', '"cela attire des oiseaux" or "les chiens courent"');
\prompt PAUSE
:cls

-- Recherche
SELECT to_tsvector('myTS', 'Les champs sont plein de blé, cela attire les oiseaux') @@
       phraseto_tsquery('myTS', 'cela attire des oiseaux');
-- unaccent en action
SELECT to_tsvector('myTS', 'Les champs sont plein de blé, cela attire les oiseaux') @@
       phraseto_tsquery('myTS', 'plein de ble') AS unaccent,
       to_tsvector('french', 'Les champs sont plein de blé, cela attire les oiseaux') @@
       phraseto_tsquery('french', 'plein de ble') AS sans_unaccent;
\prompt PAUSE
:cls

-- Stockage en table + index
CREATE TABLE fts(
	id int GENERATED ALWAYS AS IDENTITY,
	texte text,
	texte_vectorise tsvector GENERATED ALWAYS AS (to_tsvector('myTs', texte)) STORED
);
--
CREATE INDEX fts_texte_vectorise_idx ON fts USING gin(texte_vectorise);
--
INSERT INTO fts(texte) VALUES 
  ('Les champs sont plein de blé, cela attire les oiseaux'),
  ('Les chiens courent dans les champs pour faire fuir les oiseaux'),
  ('Le chien a couru dans le parking');
--
BEGIN;
SET LOCAL enable_seqscan TO off;
EXPLAIN (ANALYZE) 
  SELECT id, texte 
    FROM fts 
   WHERE texte_vectorise @@ phraseto_tsquery('myTs', 'plein de ble'); 
ROLLBACK;
\prompt PAUSE
:cls

-- résultats
SELECT id, texte 
  FROM fts 
 WHERE texte_vectorise @@ phraseto_tsquery('myTs', 'plein de ble'); 

-- Ranking et highlights
SELECT id,
       ts_headline('myTS', texte, query) AS texte, 
       ts_rank_cd(texte_vectorise, query) AS rank
  FROM fts, to_tsquery('myTs', 'chiens | oiseaux') AS query 
 WHERE texte_vectorise @@ query
 ORDER BY rank DESC;
\prompt PAUSE
:cls

-- Index fonctionnel
DROP INDEX fts_texte_vectorise_idx;
--
ALTER TABLE fts DROP COLUMN texte_vectorise;
--
CREATE INDEX fts_texte_vectorise_idx ON fts USING gin(to_tsvector('myTs', texte));
--
BEGIN;
SET LOCAL enable_seqscan TO off;
EXPLAIN (ANALYZE) 
  SELECT id, texte 
    FROM fts 
   WHERE to_tsvector('myTs', texte) @@ phraseto_tsquery('myTs', 'plein de ble'); 
ROLLBACK;
\prompt PAUSE
:cls

-- json
SELECT to_tsvector('myTS', '{"nom": "Durant", "prenom" : "Pierre", "passion" : "fruit jeux basket", "adresse" : "impasse du lac"}'::jsonb);
--
SELECT to_tsvector('myTS', '{"nom": "Durant", "prenom" : "Pierre", "passion" : "fruit jeux basket", "adresse" : "impasse du lac"}'::jsonb) @@
       to_tsquery('impasse');

