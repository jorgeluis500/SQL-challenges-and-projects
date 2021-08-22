-- Preppin Data
-- 2021 Week 26
--https://preppindata.blogspot.com/2021/06/2021-week-26-rolling-weekly-revenue.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Window functions for rolling calculations, with a windwon frame


-- STEP 1 
-- Calculate the rolling AVG and SUM for all detinations

DROP TABLE IF EXISTS t_per_dest;
CREATE TEMPORARY TABLE t_per_dest AS 
SELECT 
	*,
	AVG(revenue) OVER (
			PARTITION BY destination 
			ORDER BY ddate
			ROWS BETWEEN
			3 PRECEDING
			AND 3 FOLLOWING) 
	AS rolling_week_avg,
	SUM(revenue) OVER (
			PARTITION BY destination 
			ORDER BY ddate
			ROWS BETWEEN
			3 PRECEDING
			AND 3 FOLLOWING) 
	AS rolling_week_total
FROM pd2021w26_prep_air_dest_rev
;
--SELECT * FROM t_per_dest; -- Test

-- STEP 2
-- Group by date and calculate the rolling metrics

DROP TABLE IF EXISTS t_all_dest;
CREATE TEMPORARY TABLE t_all_dest AS 
WITH t_all_dest AS (
	SELECT 
		'All' AS destination,
		ddate,
		SUM(revenue) AS revenue
	FROM pd2021w26_prep_air_dest_rev
	GROUP BY ddate
)
SELECT 
	*,
		AVG(revenue) OVER (
			ORDER BY ddate
			ROWS BETWEEN
			3 PRECEDING
			AND 3 FOLLOWING) 
	AS rolling_week_avg,
	SUM(revenue) OVER (
			ORDER BY ddate
			ROWS BETWEEN
			3 PRECEDING
			AND 3 FOLLOWING) 
	AS rolling_week_total
FROM t_all_dest
;
--SELECT * FROM t_all_dest; -- Test

-- STEP 3
--Union both datasets (and sort)

WITH t_unioned AS (
	SELECT * FROM t_per_dest
	UNION 
	SELECT * FROM t_all_dest
)
SELECT 
	* 
FROM t_unioned
ORDER BY 
	destination,
	ddate
;