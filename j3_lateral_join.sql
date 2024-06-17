-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

SET search_path TO j3, public;
:cls

-- LATERAL ---------------------------------------------------
EXPLAIN 
SELECT relname, path 
  FROM pg_class AS c 
       LEFT JOIN LATERAL pg_relation_filepath(c.oid) AS path ON TRUE;
\prompt PAUSE
DROP TABLE users, log_activity CASCADE;
:cls


--
CREATE TABLE users (id int PRIMARY KEY, name text);
INSERT INTO users (id, name) SELECT x, 'user ' || x FROM generate_series(1, 1000) AS F(x);
--
CREATE TABLE log_activity (id int, lastlog timestamp with time zone, duration interval);
ALTER TABLE log_activity ADD FOREIGN KEY(id) REFERENCES users (id);
CREATE INDEX ON log_activity (lastlog);
INSERT INTO log_activity SELECT x, current_timestamp - INTERVAL '1 hour' * (random() * 6000)::int, INTERVAL '1 second' * (random() * 1000)::int FROM generate_series(1,1000) AS F(x), generate_series(1,5);
\prompt PAUSE

SELECT u.id, u.name, lastlog, duration
  FROM users AS u 
       CROSS JOIN LATERAL (
           SELECT lastlog, duration
	     FROM log_activity
	    WHERE id = u.id
	    ORDER BY lastlog DESC
	    LIMIT 1
	)
 WHERE u.id = 100;
--
SELECT *
  FROM log_activity
 WHERE id = 100
 ORDER BY lastlog DESC;
\prompt PAUSE
:cls

EXPLAIN 
SELECT u.name, lastlog, duration
  FROM users AS u 
       CROSS JOIN LATERAL (
           SELECT lastlog, duration
	     FROM log_activity
	    WHERE id = u.id
	    ORDER BY lastlog DESC
	    LIMIT 1
	)
 WHERE u.id = 100;
\prompt PAUSE
:cls
