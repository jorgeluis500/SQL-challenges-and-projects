-- Preppin Data
-- 2021 Week 34
--https://preppindata.blogspot.com/2021/08/2021-week-34-excelling-with-lookups.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with unnest and array 
-- Aggregations


-- STEP 0
-- Exploration

-- Sales table
--SELECT "Store", "Employee", "Jan-21", "Feb-21", "Mar-21", "Apr-21", "May-21", "Jun-21", "Jul-21"
--FROM public.pd2021w34_employee_sales_csv;

-- Targets table
--SELECT "Store", "Employee", "Monthly Target"
--FROM pd2021w34_employee_targets_csv;

-- STEP 1
-- Unpivot the values of the sales table

DROP TABLE IF EXISTS t_unpivoted ;
CREATE TEMPORARY TABLE t_unpivoted AS
SELECT
	"Store",
	"Employee",
	UNNEST(ARRAY['Jan-21', 'Feb-21', 'Mar-21', 'Apr-21', 'May-21', 'Jun-21', 'Jul-21']) AS months,
	CAST(UNNEST(ARRAY["Jan-21", "Feb-21", "Mar-21", "Apr-21", "May-21", "Jun-21", "Jul-21"]) AS INT) AS sales
FROM
	public.pd2021w34_employee_sales_csv
;
--SELECT * FROM t_unpivoted ORDER BY 1,2; -- Test

--STEP 2
-- Clean names in the targets table

DROP TABLE IF EXISTS 	t_targets ;
CREATE TEMPORARY TABLE 	t_targets AS
SELECT
	CASE 
	WHEN LEFT("Store",1) = 'S' THEN 'Stratford' 
	WHEN LEFT("Store",1) = 'W' THEN 'Wimbledon' 
	WHEN LEFT("Store",1) = 'B' THEN 'Bristol' 
	WHEN LEFT("Store",1) = 'Y' THEN 'York' 
	ELSE 'Check' END AS store_clean,
	"Store",
	"Employee",
	"Monthly Target"
FROM
	pd2021w34_employee_targets_csv
;

-- STEP 3
-- Join the targets
-- Flag months where sales were above target

DROP TABLE IF EXISTS 	t_all_data ;
CREATE TEMPORARY TABLE 	t_all_data AS  
	SELECT
		u."Store",
		u."Employee",
		u.months,
		u.sales,
		t."Monthly Target",
		CASE WHEN u.sales >= t."Monthly Target" THEN 1 ELSE 0 END AS month_above_target
	FROM
		t_unpivoted AS u
	LEFT JOIN t_targets AS t
		ON 	u."Store" = t.store_clean AND u."Employee" = t."Employee"
;
--SELECT * FROM t_all_data; -- Test


-- STEP 4
-- Calculate avg monthly sales
-- Calculate avg monthly sales as pct of monthly target
-- Calculate number of months over target, total months and pct of months over target

DROP TABLE IF EXISTS 	t_aggregations ;
CREATE TEMPORARY TABLE 	t_aggregations AS
SELECT
	"Store",
	"Employee",
	ROUND(AVG(sales),0) AS avg_monthly_sales,
	MAX("Monthly Target") AS monthly_target,
	ROUND(AVG(sales),0) / MAX("Monthly Target") AS avg_sales_pct_of_tgt,
	SUM(month_above_target) AS months_over_target,
	COUNT(*) AS total_months,
	ROUND(SUM(month_above_target) *100.0 / COUNT(*),0) AS pct_of_months_above_target
FROM t_all_data
GROUP BY 1, 2
;

--SELECT * FROM t_aggregations; -- Test

-- STEP 5
-- Filter the data so that only employees who are below 90% of their target on average remain

SELECT
	"Store",
	"Employee",
	avg_monthly_sales,
	pct_of_months_above_target,
	monthly_target
FROM
	t_aggregations
WHERE 
	avg_sales_pct_of_tgt < 0.9
;