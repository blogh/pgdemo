-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS t1; 
SET search_path TO t1, public;
DROP TABLE maultable;
DROP TABLE matablenormale;
:cls

--*** unlogged tables  *************************************************************
CREATE UNLOGGED TABLE maultable(i int, t text);
CREATE TABLE matablenormale(i int, t text);
--
SELECT relname, 
       relkind, 
       relfilenode, -- prendre note du relfilenode
       relpersistence,
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text)
  FROM pg_class 
 WHERE relname IN ('maultable', 'matablenormale');
\prompt PAUSE
:cls

-- Explain 
-- table unloggued
EXPLAIN (ANALYZE, BUFFERS, WAL) 
  INSERT INTO maultable 
         SELECT x, 'l ' || x FROM generate_series(1, 500000) AS F(x);
-- table nomale
EXPLAIN (ANALYZE, BUFFERS, WAL) 
  INSERT INTO matablenormale
         SELECT x, 'l ' || x FROM generate_series(1, 500000) AS F(x);
\prompt PAUSE
:cls

-- unlogged -> logged
SELECT pg_current_wal_lsn() AS oldlsn \gset
--
SELECT relname, 
       relkind, 
       relfilenode,
       relpersistence,
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text)
  FROM pg_class 
 WHERE relname IN ('maultable');
--
ALTER TABLE maultable SET LOGGED;
-- 
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'oldlsn'::pg_lsn));
--
SELECT relname, 
       relkind, 
       relfilenode,
       relpersistence,
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text)
  FROM pg_class 
 WHERE relname IN ('maultable');
\prompt PAUSE
:cls

-- logged -> unlogged
SELECT pg_current_wal_lsn() AS oldlsn \gset
--
SELECT relname, 
       relkind, 
       relfilenode,
       relpersistence,
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text)
  FROM pg_class 
 WHERE relname IN ('maultable');
--
ALTER TABLE maultable SET UNLOGGED;
-- 
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'oldlsn'::pg_lsn));
--
SELECT relname, 
       relkind, 
       relfilenode,
       relpersistence,
       relnamespace::regnamespace, 
       pg_relation_filepath(relname::text)
  FROM pg_class 
 WHERE relname IN ('maultable');
\prompt PAUSE
:cls
