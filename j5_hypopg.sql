CREATE SCHEMA IF NOT EXISTS j5;

\set cls '\\! clear;'
\pset null '¤'
\set ECHO all

:cls
-- *** Création des tables ************************************
DROP TABLE IF EXISTS j5.hypopg_demo;
CREATE EXTENSION IF NOT EXISTS hypopg;

CREATE TABLE j5.hypopg_demo (id int, name text, age int);
INSERT INTO j5.hypopg_demo
   SELECT id, 'name ' || id % 10000, trunc(random() * 90 + 1)  AS age
     FROM generate_series(1, 1e6) id
    ORDER  BY age ;

VACUUM (ANALYZE) j5.hypopg_demo;
\prompt PAUSE
:cls

-- Création d'index dans hypopg
EXPLAIN SELECT * FROM j5.hypopg_demo WHERE age <= 20 and name LIKE 'name 10%';

SELECT hypopg_create_index('CREATE INDEX ON j5.hypopg_demo(age);');
SELECT hypopg_create_index('CREATE INDEX ON j5.hypopg_demo(name);');
SELECT hypopg_create_index('CREATE INDEX ON j5.hypopg_demo(name, age);');
SELECT * FROM hypopg_list_indexes;
\prompt PAUSE
:cls

-- Test avec EXPLAIN
EXPLAIN SELECT * FROM j5.hypopg_demo WHERE name LIKE 'name 10%';
EXPLAIN SELECT * FROM j5.hypopg_demo WHERE age <= 20 and name LIKE 'name 10%';

\prompt PAUSE
:cls

SELECT hypopg_reset();
-- Création de l'index et vérification
CREATE INDEX ON j5.hypopg_demo(name, age);
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM j5.hypopg_demo WHERE age <= 20 and name LIKE 'name 10%';
\prompt PAUSE
:cls
