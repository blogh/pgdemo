
-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS m4;
SET search_path TO m4, public;

DROP TABLE IF EXISTS storage;
:cls

-- Theory Toast ---------------------------------------------------
--
SELECT typname, dsto
 FROM pg_type AS t
      INNER JOIN (
        VALUES ('p','plain'),     -- non compressible, inline
               ('e', 'external'), -- non compressible, external 
               ('x','etended'),   -- compressible, external
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

-- Theory Compression ---------------------------------------------------
--
SHOW default_toast_compression;

-- So what? ----------------------------------------------
--
INSERT INTO storage(t) VALUES ('10');                     -- inline uncompressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)); -- inline compressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000));-- external compressed
-- compression => pglz to lz4
ALTER TABLE storage ALTER COLUMN t SET COMPRESSION lz4;
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)); -- more compressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000));-- more compressed
-- storage extended => plain
ALTER TABLE storage ALTER COLUMN t SET STORAGE plain;
INSERT INTO storage(t) VALUES (repeat('x', 8000));        -- inline non compressed in another block !
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)); -- fail
-- storage plain => main
ALTER TABLE storage ALTER COLUMN t SET STORAGE main;
INSERT INTO storage(t) VALUES ('10');                     -- inline uncompressed
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000));-- inline compressed
-- compression => lz4 to pglz
ALTER TABLE storage ALTER COLUMN t SET COMPRESSION pglz;
INSERT INTO storage(t) VALUES (repeat('xazeazr', 100000));-- compressed well over the toast treashold (2kB) but still inlined
INSERT INTO storage(t) VALUES (repeat('xazeazr', 200000));-- compressed way too big so toasted
-- storage main => extended & toast_tuple_target = 800
ALTER TABLE storage ALTER COLUMN t SET STORAGE extended;
ALTER TABLE storage SET (toast_tuple_target = 800);               
INSERT INTO storage(t) VALUES (repeat('xazeazr', 10000)); -- external compressed (was inlined before)
--
SELECT t_ctid as line_address, raw_flags::text LIKE '%HEAP_HASEXTERNAL%' as tuple_has_toast, d.*
  FROM (VALUES (0),(1),(2)) AS block_list(block)
       , LATERAL  heap_page_item_attrs(get_raw_page('m4.storage', block_list.block), 'm4.storage'::regclass, false) AS x
       , LATERAL heap_tuple_infomask_flags(t_infomask, t_infomask2)
       , LATERAL (SELECT s.i, s.d AS desc, length(s.t) AS data_size, pg_column_size(s.t),  pg_column_compression(s.t)
                    FROM m4.storage AS s
                   WHERE s.ctid = x.t_ctid) AS d
ORDER BY d.i;
\prompt PAUSE
:cls


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

-- Taost accessed but bigger
EXPLAIN (ANALYZE, BUFFERS)
SELECT i, UPPER(t) FROM storage WHERE i = 14;
