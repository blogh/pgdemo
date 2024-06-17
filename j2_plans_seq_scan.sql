-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
:cls

-- seq scan
EXPLAIN SELECT * FROM employes;
--
EXPLAIN SELECT * FROM employes WHERE matricule=135;
\prompt PAUSE
:cls
-- // seq scan
SET max_parallel_workers_per_gather TO 5 ;
--
EXPLAIN SELECT * FROM employes_big WHERE num_service <> 4;
\prompt PAUSE
:cls
