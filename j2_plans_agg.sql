-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- Agg ---------------------------------------------------------------------
-- aggregate
EXPLAIN SELECT count(*) FROM employes;
\prompt PAUSE
:cls
-- hash aggregate
EXPLAIN SELECT fonction, count(*) FROM employes GROUP BY fonction;
\prompt PAUSE
:cls
-- group aggregate (données pré triées)
EXPLAIN SELECT fonction, count(*) FROM employes GROUP BY matricule;
\prompt PAUSE
:cls
-- mixed aggregate
EXPLAIN (ANALYZE,BUFFERS)
  SELECT manager, fonction, num_service, COUNT(*)
  FROM employes_big
  GROUP BY CUBE(manager,fonction,num_service) ;
\prompt PAUSE
:cls


