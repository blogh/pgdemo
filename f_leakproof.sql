-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

CREATE SCHEAM IF NOT EXISTS f;
SET search_path TO f, public;
:cls

-- *** setup ***************************************************************
CREATE TABLE t(n int, secret text);
--
INSERT INTO t SELECT x, 'Truc ' || x FROM generate_series(1,10) AS F(x);
--
CREATE OR REPLACE FUNCTION f_leak(text) RETURNS boolean AS $$
BEGIN
  RAISE NOTICE 'Secret is: %',$1;
  RETURN true;
END;
$$ COST 1 LANGUAGE plpgsql LEAKPROOF;
--
CREATE VIEW t_odd_sb WITH (security_barrier) AS SELECT n, secret FROM t WHERE n % 2 = 1;
\prompt PAUSE

-- Fonction leakproof
SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
--
EXPLAIN SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
\prompt PAUSE
:cls

-- 
CREATE OR REPLACE FUNCTION f_leak(text) RETURNS boolean AS $$
BEGIN
  RAISE NOTICE 'Secret is: %',$1;
  RETURN true;
END;
$$ COST 1 LANGUAGE plpgsql ;
-- Fonction non leakproof
SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
--
EXPLAIN SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
\prompt PAUSE
:cls
