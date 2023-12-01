CREATE SCHEMA IF NOT EXISTS x2;

\set cls '\\! clear;'
\pset null '¤'
\pset pager off
\set ECHO all

:cls
-- *** prewarm ! ************************************
DROP TABLE IF EXISTS x2.matable;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;

CREATE TABLE x2.matable(i int, t text);
INSERT INTO x2.matable(i,t) SELECT x, 'Numéro ' || x FROM generate_series(1, 1000000) AS F(x);
\prompt PAUSE
:cls

\df *.pg_prewarm()

SELECT pg_prewarm ('x2.matable'::regclass, 'buffer') ; -- read in DB buffer chache
\prompt PAUSE
:cls

SELECT c.relname, count(*) AS buffers, pg_size_pretty(count(*)*8192) as taille_mem
  FROM pg_buffercache b 
       INNER JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
 GROUP BY c.relname
 ORDER BY count(*)*8192 DESC
 LIMIT 10;


SELECT pg_prewarm ('x2.matable'::regclass, 'read') ; -- sync request to OS (wide support / slow) 
SELECT pg_prewarm ('x2.matable'::regclass, 'prefetch') ; -- async prefetch request to the OS (Linux)
\prompt PAUSE
:cls

-- **** autoprewarm *********************************
-- https://www.postgresql.org/docs/current/pgprewarm.html

SELECT autoprewarm_start_worker(); -- start worker
SELECT autoprewarm_dump_now(); -- force dump
SELECT * FROM pg_ls_dir('.') AS x WHERE x = 'autoprewarm.blocks'; -- the file where the blocks are dumped
\prompt PAUSE

