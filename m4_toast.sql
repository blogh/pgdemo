
-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS m4;
SET search_path TO m4, public;

CREATE EXTENSION IF NOT EXISTS pageinspect;

DROP VIEW toast_info;
DROP TABLE IF EXISTS storage;
:cls

-- Theory Toast ---------------------------------------------------
--
SELECT typname, dsto
 FROM pg_type AS t
      INNER JOIN (
        VALUES ('p','plain'),     -- non compressible, inline
               ('e', 'external'), -- non compressible, external
               ('x','extended'),  -- compressible, external
               ('m','main')       -- compressible, inline (externe en dernier recours)
       ) AS sd(isto, dsto) ON t.typstorage = sd.isto
WHERE typname in ('int4', 'numeric', 'text', 'json', 'jsonb', 'bytea');
-- non toastable types: no toast
CREATE TABLE storage(i int GENERATED ALWAYS AS IDENTITY);
SELECT relnamespace::regnamespace AS schema, oid::regclass::text AS table, reltoastrelid::regclass AS toast
  FROM pg_class
 WHERE relname = 'storage';
-- toastable: toast
DROP TABLE storage;
CREATE TABLE storage(i int GENERATED ALWAYS AS IDENTITY, d text, t text);
SELECT relnamespace::regnamespace AS schema, oid::regclass::text AS table, reltoastrelid::regclass AS toast
  FROM pg_class
 WHERE relname = 'storage';
\prompt PAUSE
:cls

SELECT reltoastrelid::regclass AS toast_table
  FROM pg_class
 WHERE relname = 'storage' \gset

CREATE OR REPLACE VIEW toast_info AS 
SELECT i, sto.ctid, count(ti.chunk_id) AS "chunks count",
       length(t) AS "data size",
       pg_column_size(t) AS "column size",
       pg_column_compression(t) AS "compression"
  FROM m4.storage AS sto
       LEFT JOIN LATERAL pg_column_toast_chunk_id(t) AS tid(tid) ON TRUE
       LEFT JOIN :toast_table AS ti ON chunk_id = tid
GROUP BY 1,2,4,5,6 ORDER BY 1;
:cls

-- Theory Compression ---------------------------------------------------
--
SHOW default_toast_compression;

-- So what? ----------------------------------------------
--
INSERT INTO storage(t) VALUES ('10') RETURNING i;                     -- inline uncompressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)) RETURNING i; -- inline compressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000)) RETURNING i;-- external compressed
--
SELECT * FROM toast_info WHERE i in (1,2,3);
\prompt PAUSE
:cls
-- compression => pglz to lz4
ALTER TABLE storage ALTER COLUMN t SET COMPRESSION lz4;
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)) RETURNING i; -- more compressed than before
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000)) RETURNING i;-- more compressed than before
--
SELECT * FROM toast_info WHERE i in (2,3,4,5);
\prompt PAUSE
:cls
-- storage extended => plain
ALTER TABLE storage ALTER COLUMN t SET STORAGE plain;
INSERT INTO storage(t) VALUES (repeat('x', 8000)) RETURNING i;        -- inline non compressed in another block !
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)) RETURNING i; -- fail
--
SELECT * FROM toast_info WHERE i in (6,7);
\prompt PAUSE
:cls
-- storage plain => main
ALTER TABLE storage ALTER COLUMN t SET STORAGE main;
INSERT INTO storage(t) VALUES ('10') RETURNING i;                     -- inline uncompressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000)) RETURNING i;-- inline compressed
--
SELECT * FROM toast_info WHERE i in (8,9);
\prompt PAUSE
:cls
-- storage main, compression => lz4 to pglz
ALTER TABLE storage ALTER COLUMN t SET COMPRESSION pglz;
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000)) RETURNING i;-- compressed well over the toast treashold (2kB) but still inlined
INSERT INTO storage(t) VALUES (repeat('xazeazr', 200000)) RETURNING i;-- compressed way too big so toasted
--
SELECT * FROM toast_info WHERE i in (10,11);
\prompt PAUSE
:cls
-- storage main => extended & toast_tuple_target = 800
ALTER TABLE storage ALTER COLUMN t SET STORAGE extended;
ALTER TABLE storage SET (toast_tuple_target = 800);
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)) RETURNING i; -- external compressed (was inlined before)
--
SELECT * FROM toast_info WHERE i in (12,13);
\prompt PAUSE
:cls
--

WITH ins AS (
   INSERT INTO storage(t) VALUES (repeat('xazeazr', 200000)), (repeat('xazeazr', 2000000))
   RETURNING i
)
SELECT * FROM ins;

-- Toast not accessed
EXPLAIN (ANALYZE, BUFFERS)
SELECT i FROM storage WHERE i = 13;

-- Toast accessed
EXPLAIN (ANALYZE, BUFFERS)
SELECT i, UPPER(t) FROM storage WHERE i = 13;

-- Toast accessed but bigger
EXPLAIN (ANALYZE, BUFFERS)
SELECT i, UPPER(t) FROM storage WHERE i = 14;
