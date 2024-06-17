-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP TABLE IF EXISTS t1, t2, t3;
:cls

-- idx scan (utilisable pour un "filtre" ou tri
SET join_collapse_limit TO 2 ;
--
CREATE TABLE t1 (id integer);
INSERT INTO t1 SELECT generate_series(1, 1000000);
CREATE TABLE t2 (id integer);
INSERT INTO t2 SELECT generate_series(1, 1000000);
ANALYZE;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
  SELECT * FROM t1
  JOIN t2 ON t1.id=t2.id;
\prompt PAUSE
:cls
--
CREATE TABLE t3 (id integer);
--
EXPLAIN (ANALYZE)
  SELECT * FROM t1
  JOIN t2 ON t1.id=t2.id
  JOIN t3 ON t2.id=t3.id;
\prompt PAUSE
SET join_collapse_limit TO 3 ;
--
EXPLAIN (ANALYZE)
  SELECT * FROM t1
  JOIN t2 ON t1.id=t2.id
  JOIN t3 ON t2.id=t3.id;
\prompt PAUSE
:cls

SHOW geqo_threshold;
\prompt PAUSE
:cls

