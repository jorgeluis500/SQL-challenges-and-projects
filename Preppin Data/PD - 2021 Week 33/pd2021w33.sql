-- Preppin Data
-- 2021 Week 33
-- https://preppindata.blogspot.com/2021/08/2021-week-33-excelling-at-adding-one.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Union
-- Date parsing with to_date

-- STEP 1
-- Create one complete data set
-- Use the Table Names field to create the Reporting Date

DROP TABLE IF EXISTS 	t_alldata ;
CREATE TEMPORARY TABLE 	t_alldata AS
SELECT *, '20210101' AS rep_date FROM public.pd2021w33_20210101_csv 
UNION ALL 
SELECT *, '20210108' AS rep_date FROM public.pd2021w33_20210108_csv 
UNION ALL 
SELECT *, '20210115' AS rep_date FROM public.pd2021w33_20210115_csv 
UNION ALL 
SELECT *, '20210122' AS rep_date FROM public.pd2021w33_20210122_csv 
UNION ALL 
SELECT *, '20210129' AS rep_date FROM public.pd2021w33_20210129_csv
;

-- STEP 2
-- Convert dates
-- Find the Minimum and Maximum date where an order appeared in the reports 
	-- Could have been done in later step for better performance/clarity

DROP TABLE IF EXISTS 	t_converted ;
CREATE TEMPORARY TABLE 	t_converted AS
SELECT
	"Orders" AS orders,
	to_date("Sale Date", 'DD/MM/YYYY') AS sale_date,
	to_date(rep_date, 'YYYYMMDD') AS reporting_date,
	MIN(to_date(rep_date, 'YYYYMMDD')) OVER (PARTITION BY "Orders") AS min_rep_date,
	MAX(to_date(rep_date, 'YYYYMMDD')) OVER (PARTITION BY "Orders") AS max_rep_date
FROM
	t_alldata
;
SELECT * FROM t_converted; -- Test


-- STEP 3
-- Add one week on to the maximum date to show when an order was fulfilled by
-- Apply this logic:
	-- The first time an order appears it should be classified as a 'New Order'
	-- Any week between 'New Order' and 'Fulfilled' status is classed as an 'Unfulfilled Order' 

DROP TABLE IF EXISTS 	t_logic1 ;
CREATE TEMPORARY TABLE 	t_logic1 AS
SELECT
	orders,
	sale_date,
	reporting_date,
	min_rep_date,
	max_rep_date,
	(max_rep_date + INTERVAL '7' DAY)::date AS fulfilled_date,
	CASE 
	WHEN reporting_date = min_rep_date THEN 'New order' 
	ELSE 'Unfulfilled' END AS order_status
FROM t_converted
;
SELECT * FROM t_logic1 ORDER BY 1,3; -- Test


WITH grouped AS (
SELECT reporting_date AS all_reporting_dates FROM t_converted GROUP BY 1 
)
SELECT * FROM grouped 
INNER JOIN t_logic1
ON fulfilled_date >= reporting_date
AND sale_date <= reporting_date
;

-- STEP 4
-- Apply this logic:
-- The week after the last time an order appears in a report (the maximum date) is when the order is classed as 'Fulfilled' 

DROP TABLE IF EXISTS 	t_logic2 ;
CREATE TEMPORARY TABLE 	t_logic2 AS
SELECT
	orders,
	sale_date,
	reporting_date,
	max_rep_date,
	fulfilled_date,
	'Fulfilled' AS order_status
FROM t_logic1
GROUP BY 1,2,3,4,5
;
--SELECT * FROM t_logic2 ORDER BY 1,3; -- Test

-- STEP 5 
-- Union both datasets

DROP TABLE IF EXISTS 	t_allstatus ;
CREATE TEMPORARY TABLE 	t_allstatus AS
SELECT
	order_status,
	orders,
	sale_date,
	reporting_date,
--	min_rep_date,
	max_rep_date
--	fulfilled_date
FROM
	t_logic1
UNION ALL
SELECT
	order_status,
	orders,
	sale_date,
	reporting_date,
--	min_rep_date,
	max_rep_date
--	fulfilled_date
FROM
	t_logic2
	;

WITH ret_del AS (
	SELECT
		*
		, CASE WHEN max_rep_date = reporting_date AND order_status = 'Fulfilled' THEN 'Delete' ELSE 'Retain' END AS retain_delete
	FROM t_allstatus
)
SELECT * FROM ret_del
WHERE retain_delete = 'Retain' -- Test
ORDER BY 2,4
;