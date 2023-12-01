\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

:cls
-- *** Tables dans le cache ************************************
CREATE EXTENSION IF NOT EXISTS pg_buffercache;

-- https://www.postgresql.org/docs/current/pgbuffercache.html
\d pg_buffercache
\prompt PAUSE
:cls

-- *** Nombre de blocs / taille par relation (tt fork confondu) ***********
SELECT c.relname,
       c.relkind,
       count(*) AS buffers,
       pg_size_pretty(count(*)*8192) as taille_mem
FROM   pg_buffercache b
INNER JOIN pg_class c
      ON b.relfilenode = pg_relation_filenode(c.oid)
        AND b.reldatabase IN (0, (SELECT oid FROM pg_database
                                  WHERE datname = current_database()))
GROUP BY c.relname, c.relkind
ORDER BY 3 DESC
LIMIT 5 ;
\prompt PAUSE
:cls

-- *** nb de bloc avec des block dirty, usage count, pinned identiques par relation (tt fork confondu) ****************
SELECT
    relname,
    relkind,
    isdirty,
    usagecount,
    pinning_backends,
    count(bufferid)
FROM pg_buffercache b
INNER JOIN pg_class c ON c.relfilenode = b.relfilenode
WHERE relname NOT LIKE 'pg%'
GROUP BY
        relname,
	relkind,
        isdirty,
        usagecount,
        pinning_backends
ORDER BY 1, 2, 3, 4, 5 ;
\prompt PAUSE
:cls
