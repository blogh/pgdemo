-- Conf
\set cls '\\! clear;'
\pset pager off
\pset null '¤'
\set ECHO all
:cls

CREATE SCHEMA IF NOT EXISTS j4; 
SET search_path TO j4, public;
DROP TABLE multic;

-- type
CREATE TABLE multic(a int, b int);
CREATE INDEX ON multic(a, b);
INSERT INTO multic(a,b) 
    SELECT x, y 
      FROM (SELECT generate_series(1, 100) AS x) 
           CROSS JOIN (SELECT generate_series(1, 100) AS y);
SELECT * FROM multic LIMIT 10;
\prompt PAUSE
:cls

-- page 0 (métapage) ---------------------------------------------------
SELECT * FROM bt_metap('j4.multic_a_b_idx') LIMIT 10;
\prompt PAUSE

-- page 3 (root) -------------------------------------------------------
-- stats
SELECT * FROM bt_page_stats('j4.multic_a_b_idx', 3) LIMIT 10;
-- données début de bloc
SELECT * FROM bt_page_items(get_raw_page('j4.multic_a_b_idx', 3)) LIMIT 10;
\prompt PAUSE
:cls

-- page 1 (leaf) ------------------------------------------------------
-- stats
SELECT * FROM bt_page_stats('j4.multic_a_b_idx', 1) LIMIT 10;
-- données début de bloc
SELECT bt.*, '0x' || lpad(to_hex(a), 4, '0') AS a, '0x' || lpad(to_hex(b), 4, '0') AS b
  FROM bt_page_items(get_raw_page('j4.multic_a_b_idx', 1)) AS bt
       LEFT JOIN LATERAL (SELECT a,b FROM j4.multic AS t WHERE bt.ctid = t.ctid AND dead IS NOT NULL) AS data ON true
 ORDER BY 1 ASC LIMIT 5;
-- données fin de bloc
SELECT * FROM (
  SELECT bt.*, '0x' || lpad(to_hex(a), 4, '0') AS a, '0x' || lpad(to_hex(b), 4, '0') AS b
    FROM bt_page_items(get_raw_page('j4.multic_a_b_idx', 1)) AS bt
         LEFT JOIN LATERAL (SELECT a,b FROM j4.multic AS t WHERE bt.ctid = t.ctid AND dead IS NOT NULL ) AS data ON true
   ORDER BY 1 DESC LIMIT 5
) ORDER BY 1;
\prompt PAUSE
:cls

-- page 2 (leaf) ------------------------------------------------------
-- stats
SELECT * FROM bt_page_stats('j4.multic_a_b_idx', 2) LIMIT 10;
-- données début de bloc
SELECT bt.*, '0x' || lpad(to_hex(a), 4, '0') AS a, '0x' || lpad(to_hex(b), 4, '0') AS b
  FROM bt_page_items(get_raw_page('j4.multic_a_b_idx', 2)) AS bt
       LEFT JOIN LATERAL (SELECT a,b FROM j4.multic AS t WHERE bt.ctid = t.ctid AND dead IS NOT NULL) AS data ON true
 ORDER BY 1 ASC LIMIT 5;
-- données fin de bloc
SELECT * FROM (
  SELECT bt.*, '0x' || lpad(to_hex(a), 4, '0') AS a, '0x' || lpad(to_hex(b), 4, '0') AS b
    FROM bt_page_items(get_raw_page('j4.multic_a_b_idx', 2)) AS bt
         LEFT JOIN LATERAL (SELECT a,b FROM j4.multic AS t WHERE bt.ctid = t.ctid AND dead IS NOT NULL ) AS data ON true
   ORDER BY 1 DESC LIMIT 5
) ORDER BY 1;
\prompt PAUSE
:cls
