
-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE SCHEMA IF NOT EXISTS v1;
SET search_path TO v1;
DROP TABLE IF EXISTS animaux CASCADE;
DROP TABLE IF EXISTS cephalopodes;
DROP TABLE IF EXISTS vertebres;
DROP TABLE IF EXISTS tetrapodes;
DROP TABLE IF EXISTS poissons;
DROP TABLE IF EXISTS t3 CASCADE;

:cls
-- *** Partitionnement par Héritage ******************************
-- Table: animaux
CREATE TABLE animaux (nom text PRIMARY KEY);
--
INSERT INTO animaux VALUES ('Éponge');
INSERT INTO animaux VALUES ('Ver de terre');
\prompt PAUSE
:cls

-- Table: animaux > cephalopodes
CREATE TABLE cephalopodes (nb_tentacules integer)
INHERITS (animaux);
--
INSERT INTO cephalopodes VALUES ('Poulpe', 8);
\prompt PAUSE
:cls

-- Table: animaux > vertebres
CREATE TABLE vertebres (
    nb_membres integer
)
INHERITS (animaux);
\prompt PAUSE
:cls

-- Table: animaux > vertebres > tetrapodes
CREATE TABLE tetrapodes () INHERITS (vertebres);
--
ALTER TABLE ONLY tetrapodes
ALTER COLUMN nb_membres
      SET DEFAULT 4;
\prompt PAUSE
:cls

-- Table: animaux > vertebres > tetrapodes > poissons
CREATE TABLE poissons (eau_douce boolean)
       INHERITS (tetrapodes);
--
INSERT INTO poissons (nom, eau_douce) 
       VALUES ('Requin', false);
INSERT INTO poissons (nom, nb_membres, eau_douce) 
       VALUES ('Anguille', 0, false);
\prompt PAUSE
:cls

-- clonnes différentes
\d+ animaux
\d+ vertebres
\d+ tetrapodes
\d+ poissons
\prompt PAUSE
:cls

-- Repartition ds tuples par "partition"
SELECT tableoid::regclass AS partition, count(*)
  FROM animaux 
 GROUP BY 1 ORDER BY 2 DESC;
\prompt PAUSE
:cls

-- Explain
EXPLAIN (ANALYZE) SELECT * FROM animaux;
EXPLAIN (ANALYZE) SELECT * FROM animaux WHERE nom = 'Requin';
\prompt PAUSE
:cls

--*** Partitionnement avec trigger et contraintes *****************
-- Création des tables
CREATE TABLE t3 (c1 integer, c2 text);
CREATE TABLE t3_1 (CHECK (c1 BETWEEN       0 AND  999999)) INHERITS (t3);
CREATE TABLE t3_2 (CHECK (c1 BETWEEN 1000000 AND 1999999)) INHERITS (t3);
CREATE TABLE t3_3 (CHECK (c1 BETWEEN 2000000 AND 2999999)) INHERITS (t3);
CREATE TABLE t3_4 (CHECK (c1 BETWEEN 3000000 AND 3999999)) INHERITS (t3);
CREATE TABLE t3_5 (CHECK (c1 BETWEEN 4000000 AND 4999999)) INHERITS (t3);
CREATE TABLE t3_6 (CHECK (c1 BETWEEN 5000000 AND 5999999)) INHERITS (t3);
CREATE TABLE t3_7 (CHECK (c1 BETWEEN 6000000 AND 6999999)) INHERITS (t3);
CREATE TABLE t3_8 (CHECK (c1 BETWEEN 7000000 AND 7999999)) INHERITS (t3);
CREATE TABLE t3_9 (CHECK (c1 BETWEEN 8000000 AND 8999999)) INHERITS (t3);
CREATE TABLE t3_0 (CHECK (c1 BETWEEN 9000000 AND 9999999)) INHERITS (t3);

\prompt PAUSE
:cls

-- Routage des lignes
CREATE OR REPLACE FUNCTION insert_into() RETURNS TRIGGER
LANGUAGE plpgsql
AS $FUNC$
BEGIN
  IF NEW.c1    BETWEEN       0 AND  999999 THEN
    INSERT INTO t3_1 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 1000000 AND 1999999 THEN
    INSERT INTO t3_2 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 2000000 AND 2999999 THEN
    INSERT INTO t3_3 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 3000000 AND 3999999 THEN
    INSERT INTO t3_4 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 4000000 AND 4999999  THEN
    INSERT INTO t3_5 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 5000000 AND 5999999 THEN
    INSERT INTO t3_6 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 6000000 AND 6999999 THEN
    INSERT INTO t3_7 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 7000000 AND 7999999  THEN
    INSERT INTO t3_8 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 8000000 AND 8999999 THEN
    INSERT INTO t3_9 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 9000000 AND 9999999 THEN
    INSERT INTO t3_0 VALUES (NEW.*);
  END IF;
  RETURN NULL;
END;
$FUNC$;

CREATE TRIGGER tr_insert_t3 BEFORE INSERT ON t3 FOR EACH ROW EXECUTE PROCEDURE insert_into();
\prompt PAUSE
:cls

-- Insertions
INSERT INTO t3(c1) VALUES (3), (1000000), (2000000), (3000000), (4000000);
-- Réparition par partition
SELECT tableoid::regclass AS partition, count(*) FROM t3 GROUP BY 1 ORDER BY 2 DESC;
\prompt PAUSE
:cls

-- Explain
EXPLAIN (ANALYZE) SELECT * FROM t3;
EXPLAIN (ANALYZE, VERBOSE) SELECT * FROM t3 WHERE c1=1000000;
\prompt PAUSE
