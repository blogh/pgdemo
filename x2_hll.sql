CREATE SCHEMA IF NOT EXISTS x2;

\set cls '\\! clear;'
\pset null '¤'
\pset pager off
\set ECHO all

:cls
-- *** hll ! ************************************
DROP TABLE IF EXISTS x2.hll_test;
-- https://github.com/citusdata/postgresql-hll
CREATE EXTENSION IF NOT EXISTS hll;
SHOW shared_preload_libraries;

CREATE TABLE x2.hll_test(id int PRIMARY KEY, nom text, absence date);

INSERT INTO x2.hll_test(id, nom, absence)
  SELECT row_number () over () as id, nom, absence
    FROM (SELECT 'nom ' || x AS nom, (random() * 10)::int AS nb_absences 
            FROM generate_series(1, 1000000) AS F(x)) AS G(nom, nb_absences)
	 CROSS JOIN LATERAL
         (SELECT current_date - INTERVAL '1 day' * (random() * 33)::int - INTERVAL '1 month' * (random() * 13)::int
	    FROM generate_series(1, nb_absences)) AS H(absence);

VACUUM ANALYZE x2.hll_test;
\prompt PAUSE
:cls

SELECT hll_set_defaults(11, 5, -1, 1); -- defaut
SELECT hll_set_defaults(17, 5, -1, 0);
DROP TABLE IF EXISTS x2.absences;
CREATE TABLE x2.absences(
	"when" date,
	who hll
);
INSERT INTO x2.absences("when", who)
    SELECT absence,
           hll_add_agg(hll_hash_text(nom))
      FROM x2.hll_test
     GROUP BY 1;
\prompt PAUSE
:cls

\timing
-- top 10 des jours avec le plus d'absences cette année
SELECT "when", hll_cardinality(who)
  FROM x2.absences
 WHERE "when" >= '2023-01-01'::date
 ORDER BY 2 DESC
 LIMIT 10;

 SELECT absence, count(distinct nom)
   FROM x2.hll_test
  WHERE absence >= '2023-01-01'::date
 GROUP BY 1
 ORDER BY 2 DESC
 LIMIT 10;
\prompt PAUSE

-- nombre de personne qui ont des absences pour chaque mois de cette année
SELECT date_trunc('month', "when")::date AS mois,
       hll_cardinality(hll_union_agg(who))
  FROM x2.absences
 WHERE "when" >= '2023-01-01'::date
 GROUP BY 1
 ORDER BY 2 DESC;

 SELECT date_trunc('month', absence)::date, count(distinct(nom))
   FROM x2.hll_test
  WHERE absence >= '2023-01-01'::date
  GROUP BY 1
  ORDER BY 2 DESC;
\prompt PAUSE
