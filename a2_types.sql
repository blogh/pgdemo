-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS a2;
SET search_path TO a2, public;

DROP TABLE IF EXISTS capitaines, application;
DROP TYPE serveur, jour_semaine;
DROP DOMAIN code_postal_francais;
DROP OPERATOR ***(int, int);
DROP FUNCTION randomresult(int, int);
:cls

-- Composite Types ---------------------------------------------------

CREATE TYPE serveur AS (
  nom             text,
  adresse_ip      inet,
  administrateur  text
);

CREATE TABLE application (
  nom text,
  serveurs serveur[]
);

INSERT INTO application 
  VALUES ('myapp', ARRAY[ ('srv1', '10.0.0.100', 'marc')::serveur, ('srv2', '10.0.0.101', 'jean')::serveur ]);

SELECT * FROM application;
SELECT serveurs[1] FROM application;
SELECT nom, (unnest(serveurs)).nom FROM application;

\prompt PAUSE
:cls

-- Operators ---------------------------------------------------
--
CREATE FUNCTION randomresult(a integer, b integer) RETURNS integer
    LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT
    RETURN random() * a * b;
--
CREATE OPERATOR *** (
    leftarg = int,
    rightarg = int,
    function = randomresult,
    commutator = ***
);
--
SELECT 10 *** 10;
\prompt PAUSE
:cls

--
CREATE TABLE capitaines (id serial, nom text, age integer, num_cartecredit text);
INSERT INTO capitaines (nom, age, num_cartecredit)
  VALUES ('Robert Surcouf', 20, '1234567890123456'),
         ('Haddock'       , 35, NULL);
:cls
-- Domaines ---------------------------------------------------
--
CREATE DOMAIN code_postal_francais AS text CHECK (value ~ '^\d{5}$');
ALTER TABLE capitaines ADD COLUMN cp code_postal_francais;
--
UPDATE capitaines SET cp = '35400' WHERE nom LIKE '%Surcouf';
UPDATE capitaines SET cp = '1420' WHERE nom = 'Haddock';
--
UPDATE capitaines SET cp = '01420' WHERE nom = 'Haddock';
--
SELECT * FROM capitaines;
\prompt PAUSE
:cls

-- Enum ---------------------------------------------------
-- (ajout possible, modif et supression des valeurs => drop create)
CREATE TYPE jour_semaine
  AS ENUM ('Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi',
  'Samedi', 'Dimanche');
ALTER TABLE capitaines ADD COLUMN jour_sortie jour_semaine;
--
UPDATE capitaines SET jour_sortie = 'Mardi' WHERE nom LIKE '%Surcouf';
UPDATE capitaines SET jour_sortie = 'Samedi' WHERE nom LIKE 'Haddock';
--
SELECT * FROM capitaines WHERE jour_sortie >= 'Jeudi';
\prompt PAUSE
:cls

DROP TABLE IF EXISTS capitaines, application;
DROP TYPE serveur, jour_semaine;
DROP DOMAIN code_postal_francais;
DROP OPERATOR ***(int, int);
DROP FUNCTION randomresult(int, int);
:cls

