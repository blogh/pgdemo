-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

SET search_path TO j2, public;
SET hash_mem_multiplier TO 2;
DROP INDEX IF EXISTS employes_big_matricule_nom_idx;
:cls

-- nested loop -------------------------------------------------------
EXPLAIN (SETTINGS) 
SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM employes_big emp
       JOIN services_big ser ON (emp.num_service = ser.num_service)
 WHERE  ser.localisation = 'Nantes' AND manager = 97;
\prompt PAUSE
:cls

-- hash join ---------------------------------------------------------
EXPLAIN (SETTINGS)
SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM  employes_big emp
        JOIN services ser ON (emp.num_service = ser.num_service);
\prompt PAUSE
:cls

-- merge join --------------------------------------------------------
-- hash
EXPLAIN (SETTINGS) 
SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM employes_big emp
       JOIN services_big ser ON (emp.num_service = ser.num_service)
 WHERE  ser.localisation = 'Nantes';
-- merge (reduction de la mémoire)
SET work_mem TO '64kB';
EXPLAIN (SETTINGS)
SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM employes_big emp
       JOIN services_big ser ON (emp.num_service = ser.num_service)
 WHERE  ser.localisation = 'Nantes';
--
RESET work_mem;
-- merge (ajout d'un tri)
EXPLAIN (SETTINGS)
SELECT matricule, nom, prenom, nom_service, fonction, localisation
  FROM employes_big emp
       JOIN services_big ser ON (emp.num_service = ser.num_service)
ORDER BY ser.num_service ASC;
\prompt PAUSE
:cls


-- semi-join ---------------------------------------------------------
-- merge join
EXPLAIN (SETTINGS)
  SELECT *
  FROM services s
  WHERE EXISTS (SELECT 1
                FROM employes_big e
                WHERE e.date_embauche>s.date_creation
                  AND s.num_service = e.num_service) ;
-- hash join: plus de mémoire
SET work_mem TO '15MB';
EXPLAIN (SETTINGS)
  SELECT *
  FROM services s
  WHERE EXISTS (SELECT 1
                FROM employes_big e
                WHERE e.date_embauche>s.date_creation
                  AND s.num_service = e.num_service) ;
\prompt PAUSE
RESET work_mem;
:cls


-- anti-join ---------------------------------------------------------
-- right anti join a partir de la 16 (not exists)
EXPLAIN (SETTINGS)
  SELECT *
  FROM services s
  WHERE NOT EXISTS (SELECT 1
                    FROM employes_big e
                    WHERE e.date_embauche>s.date_creation
                      AND s.num_service = e.num_service);
\prompt PAUSE
DROP TABLE foo;
DROP TABLE bar;
:cls


-- hash-join // -------------------------------------------------------
CREATE TABLE foo(id serial, a int);
CREATE TABLE bar(id serial, foo_a int, b int);
INSERT INTO foo(a) SELECT i*2 FROM generate_series(1,1000000) i;
INSERT INTO bar(foo_a, b) SELECT i*2, i%7 FROM generate_series(1,100) i;
VACUUM ANALYZE foo, bar;
-- // seq scan
EXPLAIN (ANALYZE, VERBOSE, COSTS OFF, SETTINGS)
SELECT foo.a, bar.b 
  FROM foo 
       JOIN bar ON (foo.a = bar.foo_a) 
 WHERE a % 3 = 0;
\prompt PAUSE

-- Ajout de lignes dans bar
INSERT INTO bar(foo_a, b) SELECT i*2, i%7 FROM generate_series(1,300000) i;
VACUUM ANALYZE bar;
-- // hash join
EXPLAIN (ANALYZE, VERBOSE, COSTS OFF, SETTINGS)
SELECT foo.a, bar.b 
  FROM foo 
       JOIN bar ON (foo.a = bar.foo_a)
 WHERE a % 3 = 0;
\prompt PAUSE
-- reduction du nombre de batchs
SET work_mem TO '15MB'; -- ou hash_mem_multilier
EXPLAIN (ANALYZE, VERBOSE, COSTS OFF, SETTINGS)
SELECT foo.a, bar.b 
  FROM foo 
       JOIN bar ON (foo.a = bar.foo_a)
 WHERE a % 3 = 0;
\prompt PAUSE
:cls:

