-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS t1; 
SET search_path TO t1, public;
:cls

--*** Temp tables  *************************************************************
SET temp_buffers TO '30MB';
CREATE TEMP TABLE matemptable(i int, t text);
CREATE INDEX ON matemptable USING btree (i);
--
INSERT INTO matemptable SELECT x, 'l ' || x FROM generate_series(1, 500000) AS F(x);
--
SELECT relname, 
       relkind, 
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text),
       pg_size_pretty(pg_relation_size(oid)) AS size
  FROM pg_class 
 WHERE relname = 'matemptable';
\prompt PAUSE
:cls

-- Explain 
-- taille de la table <= temp_buffers (local hit)
EXPLAIN (ANALYZE, BUFFERS, settings) SELECT * FROM matemptable;
-- taille de la table > temp_buffers (local read/dirty/written)
INSERT INTO matemptable SELECT x, 'l ' || x FROM generate_series(1, 500000) AS F(x);
--
EXPLAIN (ANALYZE, BUFFERS, settings) SELECT * FROM matemptable;
\prompt PAUSE
