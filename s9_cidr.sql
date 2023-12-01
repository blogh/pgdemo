-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

CREATE SCHEMA IF NOT EXISTS s9; 
SET search_path TO s9, public;
DROP TABLE adr;
:cls

-- type
SELECT  typname FROM pg_type WHERE typname IN ('cidr', 'inet', 'macaddr', 'macaddr8');

SELECT proname, pg_get_function_arguments(oid), pg_get_function_result(oid)
  FROM pg_proc 
 WHERE proargtypes::oid[] && ARRAY['cidr'::regtype::oid,'inet'::regtype::oid]
   AND prosupport IS NOT NULL
 ORDER BY 1;
\prompt PAUSE
:cls

-- ipv4
SELECT '192.168.1.0/24'::inet >> '192.168.1.10'::inet AS networkA_includes_networkB;
SELECT '192.168.1.0/24'::inet >> '192.168.2.10'::inet AS networkA_includes_networkB;
\prompt PAUSE 
:cls

-- ipv6
SELECT '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr;

-- ipv6: dropping leading zeroes
SELECT '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr,
       '2345:425:2CA1:0000:0000:567:5673:23b5'::cidr,
       '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr = '2345:425:2CA1:0000:0000:567:5673:23b5'::cidr AS is_equal; 

-- ipv6: using zero for entire groups
SELECT '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr,
       '2345:425:2CA1:0:0:567:5673:23b5'::cidr,
       '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr = '2345:425:2CA1:0:0:567:5673:23b5'::cidr AS is_equal;

-- ipv6: double colon for contiguous zeroes
SELECT '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr,
       '2345:425:2CA1::567:5673:23b5'::cidr,
       '2345:0425:2CA1:0000:0000:0567:5673:23b5'::cidr = '2345:425:2CA1::567:5673:23b5'::cidr AS is_equal;

-- ipv6: addr + mask
SELECT '2345:425:2CA1:0000:0000:567:5673:23b5/64'::inet;
\prompt PAUSE
:cls


-- indexation
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE TABLE adr(i inet);
INSERT INTO adr(i)
       SELECT ('192.168.' || (random() * 255)::int || '.' || (random() * 255)::int)::inet
         FROM generate_series(1, 100000);
CREATE INDEX ON adr USING gist(i inet_ops);
VACUUM ANALYZE adr;
\prompt PAUSE

SET enable_seqscan TO off;
EXPLAIN (ANALYZE) SELECT count(*) FROM adr WHERE i << '192.168.1.0/24'::inet;
\prompt PAUSE
:cls
