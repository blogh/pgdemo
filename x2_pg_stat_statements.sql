CREATE SCHEMA IF NOT EXISTS x2;

\set cls '\\! clear;'
\pset null '¤'
\pset pager off
\set ECHO all

:cls
-- *** pg_stat_statements ************************************
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SHOW shared_preload_libraries;
\prompt PAUSE
:cls

-- *** rquetes les plus longues en tps cummulé ************************************
SELECT r.rolname, d.datname, s.calls, s.total_exec_time,
       s.calls / s.total_exec_time AS avg_time, SUBSTRING(s.query, 1, 80) AS query
  FROM pg_stat_statements s
  JOIN pg_roles r
    ON (s.userid=r.oid)
  JOIN pg_database d
    ON (s.dbid = d.oid)
 ORDER BY s.total_exec_time DESC
 LIMIT 10;
\prompt PAUSE
:cls

-- *** rquetes les plus fréquentes ************************************
 SELECT r.rolname, d.datname, s.calls, s.total_exec_time,
       s.calls / s.total_exec_time AS avg_time, SUBSTRING(s.query, 1, 80) AS query
  FROM pg_stat_statements s
  JOIN pg_roles r
    ON (s.userid=r.oid)
  JOIN pg_database d
    ON (s.dbid = d.oid)
 ORDER BY s.calls DESC
 LIMIT 10;
\prompt PAUSE
:cls

-- *** rquetes avec le plus de temp file ************************************
 SELECT r.rolname, d.datname, s.calls, s.total_exec_time,
       temp_blks_read, temp_blks_written,
       SUBSTRING(s.query, 1, 80) AS query
  FROM pg_stat_statements s
  JOIN pg_roles r
    ON (s.userid=r.oid)
  JOIN pg_database d
    ON (s.dbid = d.oid)
 ORDER BY s.temp_blks_written DESC
 LIMIT 10;
\prompt PAUSE
:cls
