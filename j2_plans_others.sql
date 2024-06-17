-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- LIMIT ---------------------------------------------------------------------
EXPLAIN SELECT * FROM employes_big LIMIT 1;
--
EXPLAIN ANALYZE SELECT * FROM employes_big ORDER BY fonction LIMIT 5;
\prompt PAUSE
:cls


-- UNIQUE ---------------------------------------------------------------------
EXPLAIN SELECT DISTINCT matricule FROM employes_big;
\prompt PAUSE
:cls

-- append / union / intersect -------------------------------------------------
EXPLAIN
  SELECT * FROM employes
   WHERE num_service = 2
  UNION
  SELECT * FROM employes
   WHERE num_service = 4;
\prompt PAUSE
--
EXPLAIN
  SELECT * FROM employes
   WHERE num_service = 2
  UNION ALL
  SELECT * FROM employes
   WHERE num_service = 4;
\prompt PAUSE
--
EXPLAIN
  SELECT * FROM employes
   WHERE num_service = 2
  EXCEPT
  SELECT * FROM employes
   WHERE num_service = 4;
\prompt PAUSE
--
EXPLAIN
  SELECT * FROM employes
   WHERE num_service = 2
  INTERSECT
  SELECT * FROM employes
   WHERE num_service = 4;
\prompt PAUSE
:cls

-- Init Plan ------------------------------------------------------------------
-- Requête a exécuter avant de lancer la requête, ici le résultat est identique pr toutes les lignes
EXPLAIN
  SELECT *,
    (SELECT nom_service FROM services WHERE num_service=1)
  FROM employes WHERE num_service = 1;
\prompt PAUSE
:cls

-- subplan -------------------------------------------------------------------
-- sous requête
EXPLAIN
  SELECT *
    FROM employes
   WHERE num_service NOT IN (SELECT num_service 
                               FROM services
                              WHERE nom_service = 'Consultants');
\prompt PAUSE
:cls


-- gather -------------------------------------------------------------------
SET enable_indexscan TO off;
--
EXPLAIN (SETTINGS) SELECT min(date_embauche) FROM employes_big;
\prompt PAUSE
:cls

-- Memoize -------------------------------------------------------------------
SET enable_hashjoin TO off;
SET enable_merge_join TO off;
--
EXPLAIN (SETTINGS) SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM employes_big emp
       JOIN services_big ser ON (emp.num_service = ser.num_service)
 WHERE  ser.localisation = 'Nantes';
\prompt PAUSE
:cls
