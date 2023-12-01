-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all

-- Setup
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS v1;
SET search_path TO v1, public;
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
DROP TABLE IF EXISTS t3 CASCADE;
DROP TABLE IF EXISTS logs CASCADE;

:cls

--*** Partitionnement déclaratif par listes *****************
-- Création des tables
CREATE TABLE t1(c1 integer, c2 text) PARTITION BY LIST (c1);
CREATE TABLE t1_a PARTITION OF t1 FOR VALUES IN (1, 2, 3);
CREATE TABLE t1_b PARTITION OF t1 FOR VALUES IN (4, 5);
\prompt PAUSE
:cls

-- Insertions
INSERT INTO t1 VALUES (1);
INSERT INTO t1 VALUES (2);
INSERT INTO t1 VALUES (5);
\prompt PAUSE
:cls

-- Explain
EXPLAIN (ANALYZE) SELECT * FROM t1; 
EXPLAIN (ANALYZE) SELECT * FROM t1 WHERE c1 = 1;
\prompt PAUSE
:cls

-- Répartition des lignes
SELECT tableoid::regclass, * FROM t1;
SELECT * FROM t1_a ;
\prompt PAUSE
:cls

--*** Partitionnement déclaratif par intervalle *****************
-- Création des tables
CREATE TABLE t2(c1 integer, c2 text) PARTITION BY RANGE (c1);
CREATE TABLE t2_1 PARTITION OF t2 FOR VALUES FROM (1) to (100);
CREATE TABLE t2_2 PARTITION OF t2 FOR VALUES FROM (100) TO (MAXVALUE);
\prompt PAUSE
:cls

-- Insertions
INSERT INTO t2 VALUES (10, 'dix');
INSERT INTO t2 VALUES (100, 'cent'); -- borne de partition
INSERT INTO t2 VALUES (10000, 'dix mille');

-- Répartition des lignes
SELECT tableoid::regclass, * FROM t2 ;
\prompt PAUSE
:cls

--*** Partitionnement déclaratif par hachage *****************
-- Création des tables
CREATE TABLE t3(c1 integer, c2 text) PARTITION BY HASH (c1);
CREATE TABLE t3_a PARTITION OF t3 FOR VALUES WITH (modulus 3, remainder 0);
CREATE TABLE t3_b PARTITION OF t3 FOR VALUES WITH (modulus 3, remainder 1);
CREATE TABLE t3_c PARTITION OF t3 FOR VALUES WITH (modulus 3, remainder 2);
\prompt PAUSE
:cls

-- Insertions
INSERT INTO t3 SELECT generate_series(1, 1000000);
ANALYZE t3;

-- Répartition des lignes
SELECT relname,relispartition,relkind,reltuples
  FROM pg_class WHERE relname LIKE 't3%';
\prompt PAUSE
:cls

--*** Partitionnement multi-colonnes *******************
CREATE TABLE t4(c1 integer, d date, c2 text) PARTITION BY RANGE(c1, d);
CREATE TABLE t4_a PARTITION OF t4 FOR VALUES FROM (  1, '2023-01-01'::date) TO (100, '2023-02-01'::date);
CREATE TABLE t4_b PARTITION OF t4 FOR VALUES FROM (100, '2023-02-01'::date) TO (200, '2023-03-01'::date);
CREATE TABLE t4_c PARTITION OF t4 FOR VALUES FROM (200, '2023-03-01'::date) TO (300, '2023-04-01'::date);
\prompt PAUSE
:cls

--*** Partition par défaut ******************************
-- Insertion
INSERT INTO t1 VALUES (0);
--
INSERT INTO t1 VALUES (6);
--

-- Partition par défaut
CREATE TABLE t1_defaut PARTITION OF t1 DEFAULT;

-- Insertion
INSERT INTO t1 VALUES (0);
INSERT INTO t1 VALUES (6);
SELECT tableoid::regclass, * FROM t1;
\prompt PAUSE
:cls

--*** DETACH / ATTACH ***********************************
\d+ t1
\d+ t1_defaut
\prompt PAUSE
ALTER TABLE t1 DETACH PARTITION t1_defaut;
\prompt PAUSE
\d+ t1
-- la contrainte a disparu
\d+ t1_defaut
\prompt PAUSE
-- 
ALTER TABLE t1 ATTACH PARTITION t1_defaut DEFAULT ;
\d+ t1
-- la contrainte a réapparu
\d+ t1_defaut
\prompt PAUSE
--
DROP TABLE t1_defaut;
\d+ t1
\prompt PAUSE
:cls


--*** fonctions ******************************************
-- Préparation / partitionnement a plusieurs niveaux
CREATE TABLE logs (dreception timestamptz, contenu text) PARTITION BY RANGE(dreception);
CREATE TABLE logs_2018 PARTITION OF logs FOR VALUES FROM ('2018-01-01') TO ('2019-01-01')
                       PARTITION BY range(dreception);
CREATE TABLE logs_201801 PARTITION OF logs_2018 FOR VALUES FROM ('2018-01-01') TO ('2018-02-01');
CREATE TABLE logs_201802 PARTITION OF logs_2018 FOR VALUES FROM ('2018-02-01') TO ('2018-03-01');
CREATE TABLE logs_2019 PARTITION OF logs FOR VALUES FROM ('2019-01-01') TO ('2020-01-01')
                       PARTITION BY range(dreception);
CREATE TABLE logs_201901 PARTITION OF logs_2019 FOR VALUES FROM ('2019-01-01') TO ('2019-02-01');
\prompt PAUSE
:cls

-- Topologie
SELECT * FROM pg_partition_tree('logs');
SELECT * FROM pg_partition_ancestors('logs_201801');
SELECT * FROM pg_partition_root('logs_201801');
\prompt PAUSE
:cls

--*** INDEX ********************************************
-- propagation des index
ALTER TABLE logs ADD PRIMARY KEY (dreception);
CREATE INDEX ON logs USING gist (contenu gist_trgm_ops);
\d logs
\d logs_2018
\d logs_201801
