-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j0, public;
DROP VIEW IF EXISTS v_test_did;
DROP TABLE IF EXISTS test;
:cls

--
CREATE TABLE j0.test (id int GENERATED ALWAYS AS IDENTITY, valeur int);
INSERT INTO test(valeur) SELECT generate_series(1, 1000000);
--
CREATE OR REPLACE VIEW v_test_did
AS SELECT DISTINCT ON (id) id,valeur FROM test ;
--
EXPLAIN (ANALYZE, COSTS OFF)
  SELECT id,valeur
  FROM v_test_did
  WHERE valeur=1000 ;
--
EXPLAIN (ANALYZE, COSTS OFF)
  SELECT id,valeur
  FROM test
  WHERE valeur=1000 ;

