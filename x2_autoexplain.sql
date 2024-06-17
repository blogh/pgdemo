CREATE SCHEMA IF NOT EXISTS x2;

\set cls '\\! clear;'
\pset null '¤'
\pset pager off
\set ECHO all

:cls
-- *** autoepxlain ! ************************************
LOAD 'auto_explain';
SET auto_explain.log_analyze TO true;
SET auto_explain.log_min_duration TO 0;
SET client_min_messages TO log;
--
SELECT * FROM pg_class c INNER JOIN pg_namespace n ON n.oid = c.relnamespace LIMIT 1;
--
\prompt PAUSE
:cls

CREATE OR REPLACE FUNCTION fulltname(oid) RETURNS text AS $$
DECLARE
	ftname TEXT;
BEGIN
	SELECT nspname || '.' || relname
	  INTO ftname
	  FROM pg_class c 
	       INNER JOIN pg_namespace n ON n.oid = c.relnamespace
	 WHERE c.oid = $1;
	 RETURN ftname;
END;
$$ LANGUAGE plpgsql;
--
SELECT fulltname('pg_class'::regclass::oid);
--
SET auto_explain.log_nested_statements TO on;
--
SELECT fulltname('pg_class'::regclass::oid);
--

\prompt PAUSE
:cls

