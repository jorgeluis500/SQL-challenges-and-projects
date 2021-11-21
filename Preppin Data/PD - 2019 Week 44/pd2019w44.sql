-- Preppin Data
-- 2019 Week 44
-- https://preppindata.blogspot.com/2019/12/2019-week-44.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Union to unpivot
-- Joins, aggregations and ranks

-- Unpivot the sales

DROP TABLE IF EXISTS 	unpivoted_sales ;
CREATE TEMPORARY TABLE 	unpivoted_sales AS
	SELECT
		sale_date,
		'Wimbledon' AS store,
		wimbledon AS sales
	FROM
		public.pd2019w44_store_sales_csv
UNION
	SELECT
		sale_date,
		'Lewisham' AS store,
		lewisham AS sales
	FROM
		public.pd2019w44_store_sales_csv
;

--SELECT * FROM unpivoted_sales ; -- Test

-- STEP 2
-- Determine how many staff work in each store each day
-- Join Store Sales and Team Member Days
-- Estimate the Staff Sales per Day based on the Store Sales divided by the number of staff who worked that day

DROP TABLE IF EXISTS 	staff_sales ;
CREATE TEMPORARY TABLE 	staff_sales AS
WITH daily_staff AS (
SELECT
		sale_date,
		store,
		Count(team_member) AS staff_each_day
FROM
		public.pd2019w44_team_member_days_csv
GROUP BY
	1,
	2
)
SELECT
	df.sale_date,
	df.store,
	us.sales,
	df.staff_each_day,
	(us.sales / df.staff_each_day) AS estimated_staff_sales_per_day
FROM
	daily_staff AS df
INNER JOIN unpivoted_sales AS us
	ON
	df.sale_date = us.sale_date
	AND df.store = us.store
;

--SELECT * FROM staff_sales; -- Test

-- STEP 3
-- Join back with team members daily attendance table
-- Estimate teh average sales per member per store
-- Rank them

WITH est_sales_per_day AS (
SELECT
	ss.sale_date,
	ss.store,
	ss.sales,
	ss.staff_each_day,
	ss.estimated_staff_sales_per_day,
	tm.team_member
FROM
	staff_sales ss
INNER JOIN pd2019w44_team_member_days_csv tm
ON
	ss.sale_date = tm.sale_date
	AND ss.store = tm.store
)
, avg_sales_per_staff_and_store AS (
	SELECT
		store,
		team_member,
		round(avg(estimated_staff_sales_per_day), 2) AS estimated_sales_per_staff_member
	FROM
		est_sales_per_day 
	GROUP BY
		1,
		2
) -- FINAL ranks
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY store ORDER BY estimated_sales_per_staff_member DESC) AS sales_rank
FROM avg_sales_per_staff_and_store
ORDER BY 
	store, 
	estimated_sales_per_staff_member DESC
;