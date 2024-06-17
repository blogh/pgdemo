-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS a2;
SET search_path TO a2, public;

DROP TABLE IF EXISTS t2, capitaines;
:cls

-- Default ---------------------------------------------------
--
CREATE TABLE t2 (c1 integer, c2 integer, c3 integer DEFAULT 10);
INSERT INTO t2 (c1, c2, c3) VALUES (1, 2, 3);
INSERT INTO t2 (c1) VALUES (2);
--
SELECT * FROM t2;
\prompt PAUSE
:cls

--
CREATE TABLE capitaines (id serial, nom text, age integer, num_cartecredit text);
INSERT INTO capitaines (nom, age, num_cartecredit)
  VALUES ('Robert Surcouf', 20, '1234567890123456'),
         ('Haddock'       , 35, NULL);

:cls
-- Generated Cols as stored ----------------------------------
--
ALTER TABLE capitaines
  ADD COLUMN num_cc_anon text
  GENERATED ALWAYS AS (substring(num_cartecredit, 0, 10) || '******') STORED;
--
SELECT nom, num_cartecredit, num_cc_anon FROM capitaines;
\prompt PAUSE

--
INSERT INTO capitaines VALUES
  (2, 'Joseph Pradere-Niquet', 40, '9876543210987654', 'test');
--
INSERT INTO capitaines VALUES
  (2, 'Joseph Pradere-Niquet', 40, '9876543210987654');
--
SELECT nom, num_cartecredit, num_cc_anon FROM capitaines;
--
\prompt PAUSE
:cls

-- Generated Cols as identity ----------------------------------
--
ALTER TABLE capitaines
  ADD COLUMN id2 integer GENERATED ALWAYS AS IDENTITY;
--
SELECT nom, id2 FROM capitaines;
--
INSERT INTO capitaines (nom) VALUES ('Tom Souville');
--
SELECT nom, id2 FROM capitaines;
--
\d capitaines
--
\prompt PAUSE
:cls
DROP TABLE IF EXISTS t2, capitaines;
:cls
