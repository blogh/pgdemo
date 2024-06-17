- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS a2;
SET search_path TO a2, public;
DROP TABLE IF EXISTS capitaines;
:cls

-- Transactions ---------------------------------------------------

-- COMMIT, DDL dans un bloc de transaction
BEGIN;
CREATE TABLE capitaines (id serial, nom text, age integer);
INSERT INTO capitaines VALUES (1, 'Haddock', 35);
SELECT age FROM capitaines;
COMMIT;

SELECT age FROM capitaines;
\prompt PAUSE
:cls

-- ROLLBACK, DDL dans un bloc de transaction
BEGIN;
\dt capitaines
DROP TABLE capitaines;
\dt capitaines
ROLLBACK;

SELECT age FROM capitaines;
DROP TABLE capitaines;
\prompt PAUSE
:cls

-- SAVEPOINT, ROLLACK TO SAVEPOINT
BEGIN;
CREATE TABLE capitaines (id serial, nom text, age integer);
INSERT INTO capitaines VALUES (1, 'Haddock', 35);
SAVEPOINT insert_sp;
UPDATE capitaines SET age = 45 WHERE nom = 'Haddock';
ROLLBACK TO SAVEPOINT insert_sp;
COMMIT;

SELECT age FROM capitaines WHERE nom = 'Haddock';
\prompt PAUSE
:cls

-- Note sur le statut de la sessions et transactions
\d pg_stat_activity

\prompt PAUSE
:cls
DROP TABLE capitaines;
:cls
