-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

DROP SCHEMA f CASCADE;

CREATE SCHEMA IF NOT EXISTS f;
SET search_path TO f, public;
:cls

-- *** setup ***************************************************************
CREATE TABLE t(n int, secret text);
--
INSERT INTO t SELECT x, 'Truc ' || x FROM generate_series(1,10) AS F(x);
--
CREATE VIEW t_odd_sb AS SELECT n, secret FROM t WHERE n % 2 = 1;
--
CREATE OR REPLACE FUNCTION f_leak(text) RETURNS boolean AS $$
BEGIN
  RAISE NOTICE 'Secret is: %',$1;
  RETURN true;
END;
$$ COST 1 LANGUAGE plpgsql;
--
\prompt PAUSE
:cls

--
SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
--
EXPLAIN SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
\prompt PAUSE
:cls

-- Security barrier 
CREATE OR REPLACE VIEW t_odd_sb WITH (security_barrier) AS SELECT n, secret FROM t WHERE n % 2 = 1;
--
SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
--
EXPLAIN SELECT * FROM t_odd_sb WHERE f_leak(secret) AND n < 4;
\prompt PAUSE
:cls
