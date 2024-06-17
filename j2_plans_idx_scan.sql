-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- idx scan (utilisable pour un "filtre" ou tri
EXPLAIN SELECT * FROM employes_big WHERE matricule = 132;
\prompt PAUSE
:cls



-- idx only scan (requiert que les données de visibilité soient à jour ie VACUUM)
EXPLAIN SELECT matricule FROM employes_big WHERE matricule < 132;
--
CREATE UNIQUE INDEX ON employes_big (matricule) INCLUDE (nom) ;
--
EXPLAIN SELECT matricule, nom FROM employes_big WHERE matricule < 132;
\prompt PAUSE
:cls



-- bitmap index scan (+ bit map heapscan, bitmap and/or)
SET enable_indexscan TO off ;
--
EXPLAIN
  SELECT * FROM employes_big WHERE matricule BETWEEN 200000 AND 300000;
--EXPLAIN
EXPLAIN
  SELECT * FROM employes_big
  WHERE matricule BETWEEN   1000 AND 100000
     OR matricule BETWEEN 200000 AND 300000;
\prompt PAUSE
RESET enable_indexscan;
SET debug_parallel_query TO on; --triche !!
:cls


-- // idx scan
SET parallel_setup_cost TO 1;
SET random_page_cost TO 1;
EXPLAIN SELECT matricule, nom FROM employes_big WHERE matricule > 132;
\prompt PAUSE
:cls
