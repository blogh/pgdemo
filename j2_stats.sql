-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
:cls


-- sélectivité et choix de plan  ---------------------------------------------------
-- faible sélectivité
EXPLAIN (ANALYZE, TIMING OFF)
  SELECT *
  FROM employes_big
  WHERE date_embauche='2006-09-01';

-- forte selectivité
EXPLAIN (ANALYZE, TIMING OFF)
  SELECT *
  FROM employes_big
  WHERE date_embauche='2006-01-01';
\prompt PAUSE
:cls

-- stats monocolonnes ------------------------------------------------------------
-- pg_stats 
ANALYZE employes;
--
SELECT * FROM pg_stats
  WHERE  schemaname = 'j2'
  AND tablename     = 'employes'
  AND attname       = 'date_embauche' \gx
--
SHOW default_statistics_target;
\prompt PAUSE
:cls


DROP STATISTICS IF EXISTS stat_services_big;
:cls
-- stats multicolonnes : dépendances fonctionnelles --------------------------------
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE localisation='Paris';
--
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE departement=75;
--
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE localisation='Paris'
  AND departement=75;
\prompt PAUSE
--
CREATE STATISTICS stat_services_big (dependencies)
  ON localisation, departement
  FROM services_big;
--
ANALYZE services_big;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE localisation='Paris'
  AND departement=75;
-- attention : la requête doit obéir aux dépendances fonctionnelles
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE localisation='Paris'
  AND departement=44;
-- attention : ne fonctionne qu'avec =
EXPLAIN (ANALYZE)
  SELECT * FROM services_big
  WHERE localisation='Paris'
  AND departement>74;
\prompt PAUSE
:cls
--
SELECT * 
  FROM pg_stats_ext
 WHERE tablename = 'services_big' \gx
--
SELECT attnum, attname 
  FROM pg_attribute 
 WHERE attrelid = 'j2.services_big'::regclass 
   AND attnum IN (3,4);
\prompt PAUSE
:cls


DROP STATISTICS IF EXISTS stat_services_big;
:cls
-- stats multicolonnes : ndistinct -------------------------------------------
EXPLAIN (ANALYZE)
  SELECT localisation, COUNT(*)
  FROM   services_big
  GROUP BY localisation ;
--
EXPLAIN (ANALYZE)
  SELECT localisation, departement, COUNT(*)
  FROM services_big
  GROUP BY localisation, departement;
\prompt PAUSE
--
CREATE STATISTICS stat_services_big (ndistinct)
  ON localisation, departement
  FROM services_big;
--
ANALYZE services_big ;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
  SELECT localisation, departement, COUNT(*)
  FROM services_big
  GROUP BY localisation, departement;
--
\prompt PAUSE
:cls
--
SELECT * 
  FROM pg_stats_ext
 WHERE tablename = 'services_big' \gx
--
SELECT attnum, attname 
  FROM pg_attribute 
 WHERE attrelid = 'j2.services_big'::regclass 
   AND attnum IN (3,4);
\prompt PAUSE
:cls


DROP STATISTICS IF EXISTS stat_services_big;
:cls
-- stats multicolonnes : mcv -------------------------------------------
EXPLAIN (ANALYZE)
  SELECT *
  FROM services_big
  WHERE localisation='Paris'
  AND  departement > 74 ;
\prompt PAUSE
--
CREATE STATISTICS stat_services_big (mcv)
  ON localisation, departement
  FROM services_big;
--
ANALYZE services_big;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
  SELECT *
  FROM services_big
  WHERE localisation='Paris'
  AND  departement > 74 ; 

\prompt PAUSE
:cls
--
SELECT * 
  FROM pg_stats_ext
 WHERE tablename = 'services_big' \gx
\prompt PAUSE
:cls


DROP STATISTICS IF EXISTS employe_big_extract;
DROP INDEX IF EXISTS employes_big_exp;
:cls
-- stats sur expression ------------------------------------------------
EXPLAIN (ANALYZE)
SELECT * 
  FROM employes_big
 WHERE extract('year' from date_embauche) = 2006 ;
\prompt PAUSE
-- Ancienne réponse
CREATE INDEX employes_big_exp ON employes_big(extract('year' from date_embauche));
--
ANALYZE employes_big;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
SELECT * 
  FROM employes_big
 WHERE extract('year' from date_embauche) = 2006 ;
\prompt PAUSE
:cls
-- Nouvelle méthode
DROP INDEX IF EXISTS employes_big_exp;
--
CREATE STATISTICS employe_big_extract
    ON extract('year' FROM date_embauche) FROM employes_big;
--
ANALYZE employes_big;
\prompt PAUSE
--
EXPLAIN (ANALYZE)
SELECT * 
  FROM employes_big
 WHERE extract('year' from date_embauche) = 2006 ;
\prompt PAUSE
:cls
--
SELECT * 
  FROM pg_stats_ext
 WHERE tablename = 'employes_big' \gx
 --
SELECT * 
  FROM pg_stats_ext_exprs
 WHERE tablename = 'employes_big' \gx
\prompt PAUSE
:cls

