-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS s9; 
SET search_path TO s9, public;
DROP TABLE IF EXISTS personnes;
:cls

--*** Jsonb *************************************************************
-- Création des tables
CREATE TABLE personnes (datas jsonb );
INSERT INTO personnes  (datas) VALUES ('
{
  "firstName": "Jean",
  "lastName": "Valjean",
  "address": {
    "streetAddress": "43 rue du Faubourg Montmartre",
    "city": "Paris",
    "postalCode": "75002"
  },
  "phoneNumbers": [
    { "number": "06 12 34 56 78" },
    {"type": "bureau",
     "number": "07 89 10 11 12"}
  ],
  "children": [],
  "spouse": null
}
'),
('
{
  "firstName": "Georges",
  "lastName": "Durand",
  "address": {
    "streetAddress": "27 rue des Moulins",
    "city": "Châteauneuf",
    "postalCode": "45990"
  },
  "phoneNumbers": [
    { "number": "06 21 34 56 78" },
    {"type": "bureau",
     "number": "07 98 10 11 12"}
  ],
  "children": [],
  "spouse": null
}
');
\prompt PAUSE
:cls

-- Accès
SELECT datas->>'firstName' AS prenom,    -- text
       datas->'address'    AS addr       -- jsonb
       FROM personnes ;
SELECT datas->>'firstName' AS prenom,    -- text
       datas->'address'    AS addr       -- jsonb
       FROM personnes \gdesc
\prompt PAUSE
:cls
-- Données avec hierachie : address > city
SELECT datas #>> '{address,city}' AS villes FROM personnes ; -- text
SELECT datas #>> '{address,city}' AS villes FROM personnes \gdesc
SELECT datas #> '{address,city}' AS villes FROM personnes \gdesc
\prompt PAUSE
:cls
-- Données avec hierachie : address > city
SELECT datas['address']['city'] as villes from personnes ;  -- jsonb, v14
SELECT datas['address']['city'] as villes from personnes \gdesc
\prompt PAUSE
:cls
-- Données avec hierachie : address > city
SELECT datas['address']->>'city' as villes from personnes ;  -- text, v14
SELECT datas['address']->>'city' as villes from personnes \gdesc
\prompt PAUSE
:cls
-- phoneNumbers est un tableau  de {"type","number}
SELECT jsonb_array_elements (datas->'phoneNumbers')->>'number' AS numeros FROM personnes;
SELECT jsonb_array_elements (datas->'phoneNumbers')->>'number' AS numeros FROM personnes \gdesc
\prompt PAUSE
:cls

--** jsonb -> relationnel ******************************************************************************
-- 1 record => 1 jsonb
SELECT jsonb_build_object(k,v)
  FROM (VALUES ('version', version()::text), 
               ('uptime', (current_timestamp - pg_postmaster_start_time())::text)) AS F(k,v);
\prompt PAUSE
-- ensemble des records => 1 jsonb
SELECT jsonb_object_agg(k,v)
  FROM (VALUES ('version', version()::text), 
               ('uptime', (current_timestamp - pg_postmaster_start_time())::text)) AS F(k,v);
\prompt PAUSE
:cls

-- Conversion attributs jsonb => tuple (k,v)
SELECT datas->>'lastName', f.*
  FROM s9.personnes
       LEFT OUTER JOIN LATERAL jsonb_each(datas) AS f ON true
 WHERE datas->>'lastName' = 'Durand';
\prompt PAUSE
:cls

-- Conversion record jsonb => record
SELECT f.* 
  FROM s9.personnes 
       LEFT OUTER JOIN LATERAL jsonb_to_record(datas) AS f(
          "firstName" text, 
	  "lastName" text, 
	  "phoneNumbers" jsonb) ON true \gx
\prompt PAUSE
:cls


--*** Indexation *************************************************************************************
-- btree
CREATE INDEX ON personnes((datas->>'lastName'));
ANALYZE personnes;
SET enable_seqscan TO off;
--
EXPLAIN (ANALYZE) SELECT * FROM personnes WHERE datas->>'lastName' = 'Durand';
\prompt PAUSE
:cls

-- gin 
CREATE INDEX ON personnes USING gin (datas jsonb_path_ops);
--
EXPLAIN (ANALYZE) SELECT * FROM personnes WHERE datas @> '{"lastName" : "Durand"}';
\prompt PAUSE
:cls




