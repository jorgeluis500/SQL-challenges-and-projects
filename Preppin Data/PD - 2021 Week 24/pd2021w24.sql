-- Preppin Data
-- 2021 Week 24
-- https://preppindata.blogspot.com/2021/06/2021-week-24-c-co-absence-monitoring.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Date parsing with to_date
-- Scaffolding with recursive query
-- Aggregations


-- STEP 1
-- Fix the start_date attributes and convert it to type date
-- Create an end date

DROP TABLE IF EXISTS t_nsd;
CREATE TEMPORARY TABLE t_nsd AS
WITH nsd AS ( -- nsd: new start date
	SELECT 
		*, 
		CASE WHEN right(start_date, 4) <> '2021' THEN start_date ||'/2021' ELSE start_date END AS start_date_fixed
	FROM pd2021w24_reasons
	)
SELECT
	person_name,
	to_date(start_date_fixed, 'dd/mm/yyyy') AS new_start_date,
	to_date(start_date_fixed, 'dd/mm/yyyy') + days_off - 1 AS end_date,
	days_off,
	reason,
	1 AS join_col
FROM nsd
;
SELECT * FROM t_nsd; -- Test

--STEP 2
--Create the scaffolding with a recursive query

--SELECT min(new_start_date) + 1 as test FROM t_nsd; -- Test

DROP TABLE IF EXISTS t_scf;
CREATE TEMPORARY TABLE t_scf AS
WITH RECURSIVE scf (n, date_scf, join_col) AS 
(
	SELECT
	1,
	(SELECT min(new_start_date) FROM t_nsd),
	1
	UNION ALL
	SELECT 
	n + 1,
	date_scf + 1,
	join_col
	FROM scf
	WHERE n <= 60
)
SELECT * FROM scf
;
--SELECT * FROM t_scf; -- Test

-- STEP 3
-- Join both datasets limiting the number of dates with the number of days off

DROP TABLE IF EXISTS t_all_data;
CREATE TEMPORARY TABLE t_all_data AS 
SELECT
	a.person_name,
	a.new_start_date,
	a.end_date,
	a.days_off,
	a.reason,
	b.date_scf AS absent_date,
	CASE WHEN b.date_scf BETWEEN a.new_start_date AND a.end_date THEN 1 ELSE 0 END AS absent_day
FROM t_nsd a
INNER JOIN t_scf b
	ON a.join_col = b.join_col

;
--SELECT * FROM t_all_data; -- Test

-- STEP 4
-- Final dataset. Aggregate by date

SELECT
	absent_date,
	SUM(absent_day) AS number_of_people_abset_each_day
FROM
	t_all_data
GROUP BY 
	absent_date
ORDER BY 
	absent_date
;

-- QUESTIONS
-- 1. What date had the most people off?

SELECT
	absent_date,
	SUM(absent_day) AS number_of_people_absent_each_day
FROM
	t_all_data
GROUP BY 
	absent_date
ORDER BY 
	number_of_people_abnset_each_day DESC
LIMIT 1
;

--|absent_date|number_of_people_abset_each_day|
--|-----------|-------------------------------|
--|2021-04-08 |4                              |

-- 2. How many days does no-one have time off on?

WITH days AS (
	SELECT
		absent_date,
		SUM(absent_day) AS number_of_people_absent_each_day
	FROM
		t_all_data
	GROUP BY 
		absent_date
	ORDER BY 
		1
)
SELECT
	COUNT(*) AS no_time_off
FROM
	days
WHERE 
	number_of_people_absent_each_day = 0
;

--|no_time_off|
--|-----------|
--|35         |

	