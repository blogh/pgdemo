-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS s8;
SET search_path TO s8, public;

DROP TABLE IF EXISTS matable;
:cls

-- UNIQUE ---------------------------------------------------
CREATE TABLE matable(i int, j int, k int);
--
ALTER TABLE matable SET (autovacuum_enabled = off);
--
INSERT INTO matable SELECT x,x,x FROM generate_series(1, 100000) AS F(x);
--
ALTER TABLE matable ADD PRIMARY KEY (i);
ALTER TABLE matable ADD UNIQUE (j);
--
EXPLAIN SELECT * FROM matable WHERE i = 1;
--
EXPLAIN SELECT * FROM matable WHERE j = 1;
--
EXPLAIN SELECT * FROM matable WHERE k = 1;
\prompt PAUSE
DROP TABLE IF EXISTS matable, matableref, matablefk, matablenofk CASCADE;
:cls

\prompt PAUSE
:cls
