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
CREATE TABLE elt(id int, nom  text, prive bool);
---
INSERT INTO elt(id, nom, prive) SELECT x, 'Mr ' || x, true FROM generate_series(1, 5) AS f(x);
UPDATE elt SET prive = false WHERE id = 2;
--
CREATE OR REPLACE VIEW velt WITH (security_barrier) AS 
  SELECT *
   FROM elt 
  WHERE NOT prive
WITH CHECK OPTION;
\prompt PAUSE
:cls

SELECT * FROM velt;
--
UPDATE velt SET prive = true WHERE id = 2;
\prompt PAUSE
:cls

CREATE OR REPLACE VIEW velt WITH (security_barrier) AS 
  SELECT *
   FROM elt 
  WHERE NOT prive
;
--
UPDATE velt SET prive = true WHERE id = 2;
--
SELECT * FROM velt;
\prompt PAUSE
:cls

