-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

DROP TABLE IF EXISTS public.t1, public.t2, public.t3;
DROP SCHEMA IF EXISTS s1,s2 CASCADE;
:cls

-- Schemas ---------------------------------------------------

CREATE SCHEMA s1;
CREATE SCHEMA s2;

-- search path par défaut
\dn
SHOW search_path;
\prompt PAUSE

CREATE TABLE t1 (id integer);
\d
\prompt PAUSE
:cls

-- modifier le search path
SET search_path TO s1;
CREATE TABLE t2 (id integer);
\d
\prompt PAUSE
:cls

-- plusieurs schemas dans le search path
SET search_path TO s1, public;
\d
\prompt PAUSE
:cls

-- specifier le schéma a la création d'une table
CREATE TABLE s2.t3 (id integer);
SET search_path TO s1, s2, public;
\d
\prompt PAUSE
:cls

-- collision de noms
CREATE TABLE s2.t2 (id integer);
SHOW search_path;
\d
\dt s1.*
\dt s2.*
\prompt PAUSE
:cls
