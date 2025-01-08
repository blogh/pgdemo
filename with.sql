-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all


DROP SCHEMA IF EXISTS twith CASCADE;
CREATE SCHEMA twith;
CREATE TABLE fake();
CREATE TABLE twith.fake(); 
:cls

-- Agencer une série de modifications
SET search_path TO twith;
--
CREATE TABLE t(i int, j int, t text);
INSERT INTO t SELECT generate_series(1,100000), random() * 100, 'first try';
--
CREATE TABLE th(typ text, i int, j int, t text);
--
WITH update_100 AS (
  UPDATE t 
     SET j = random() * 100, t = 'reroll' 
   WHERE j > 95 
   RETURNING *
), histo AS (
  INSERT INTO th (typ, i, j ,t) SELECT 'REROLL', * FROM update_100
   RETURNING *
)
SELECT count(*) FROM histo;

\prompt PAUSE
:cls

-- Dans une requête ? -> réutiliser un portion de code plusieurs fois
WITH mdl AS (
  SELECT relname, relnamespace, relpages FROM pg_class
)
SELECT relname FROM mdl WHERE relnamespace = 'public'::regnamespace
INTERSECT
SELECT relname FROM mdl WHERE relnamespace = 'twith'::regnamespace;

\prompt PAUSE
:cls

-- Difference avec une table normale ?
EXPLAIN (ANALYZE, BUFFERS)
  SELECT * 
    FROM pg_class c 
         INNER JOIN pg_index i ON c.oid = i.indrelid 
   WHERE relnamespace = 'public'::regnamespace;
\prompt PAUSE

EXPLAIN (ANALYZE, BUFFERS)
  WITH class AS (
    SELECT * 
      FROM pg_class c 
     WHERE relnamespace = 'public'::regnamespace
  ) SELECT * 
      FROM class c 
          INNER JOIN pg_index i ON c.oid = i.indrelid;
\prompt PAUSE

EXPLAIN (ANALYZE, BUFFERS)
  WITH class AS  MATERIALIZED (
    SELECT * 
      FROM pg_class c 
     WHERE relnamespace = 'public'::regnamespace
  ) SELECT * 
      FROM class c 
          INNER JOIN pg_index i ON c.oid = i.indrelid;
\prompt PAUSE

EXPLAIN (ANALYZE, BUFFERS)
  WITH class AS NOT MATERIALIZED ( 
    SELECT * 
      FROM pg_class c 
     WHERE relnamespace = 'public'::regnamespace
  ) SELECT * 
      FROM class c 
          INNER JOIN pg_index i ON c.oid = i.indrelid;
\prompt PAUSE
:cls

-- Requêtes récursives

CREATE TABLE tree(id int, parent_id int, name text);
ALTER TABLE tree ADD PRIMARY KEY (id);
INSERT INTO tree(id, parent_id, name)
VALUES (1, NULL, 'Albert'),
       (2, 1, 'Bob'),
       (3, 1, 'Barbara'),
       (4, 1, 'Britney'),
       (5, 3, 'Clara'),
       (6, 3, 'Clement'),
       (7, 2, 'Craig'),
       (8, 5, 'Debby'),
       (9, 5, 'Dave'),
       (10, 9, 'Edwin');
\prompt PAUSE
:cls
-- https://public.dalibo.com/exports/formation/workshops/fr/ws14/140-postgresql_14.handout.html#nouvelles-clauses-search-et-cycle
--- ajout d'un champ profondeur (depth)
WITH RECURSIVE mtree(id, name, depth) AS (
   -- initialisation de la profondeur à 0 pour le point de départ
   SELECT id, name, 0
     FROM tree
    WHERE id = 1

   UNION ALL

   -- Incrémenter la profondeur de 1
   SELECT t.id, t.name, m.depth + 1
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
)
SELECT * FROM mtree ORDER BY depth DESC LIMIT 1;
\prompt PAUSE
:cls






