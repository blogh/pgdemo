-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- fct scan
EXPLAIN SELECT * from pg_get_keywords();

-- value scan
EXPLAIN SELECT * FROM ( VALUES (1),(2) ) AS F(x);

-- tid scan 
EXPLAIN SELECT * FROM employes_big WHERE ctid = '(0,1)';
