-- Preppin Data
-- 2019 Week 31
-- https://preppindata.blogspot.com/2019/09/2019-week-31.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Pivot with CASE WHEN
-- Aggregations

-- STEP 1 Pivot the table

DROP TEMPORARY TABLE IF EXISTS t_pivoted;
CREATE TEMPORARY TABLE t_pivoted AS
SELECT
	`Order`,
-- 	`Date`,
	Customer,
-- 	Status,
	MAX(CASE WHEN Status = 'Purchased' THEN `Date`ELSE NULL END) AS purchased_date,
	MAX(CASE WHEN Status = 'Sent' THEN `Date`ELSE NULL END) AS sent_date,
	MAX(CASE WHEN Status = 'Reviewed' THEN `Date`ELSE NULL END) AS reviewed_date,
	City
FROM
	pd2019w31_northern_customer_orders_csv
GROUP BY 
	`Order`,
-- 	`Date`,
	Customer,
-- 	Status,
	City
;
-- SELECT * FROM t_pivoted; -- Test

-- STEP 2 
-- Calculate the days after sent and reviewed

DROP TEMPORARY TABLE IF EXISTS t_days;
CREATE TEMPORARY TABLE t_days AS
SELECT
	*,
	sent_date - purchased_date AS days_sent,
	reviewed_date - sent_date AS days_review
FROM
	t_pivoted
;
-- SELECT * FROM t_days; -- Test

-- STEP 3
-- Calculate the averages

-- 1. Average Time for a customer to have their order sent after placing their order

SELECT
	Customer,
	AVG(days_sent) AS avg_time_to_send
FROM
	t_days 
GROUP BY 
	Customer
;	

-- 2. Average Time for a customer to review their products after we sent their order (for those that have reviewed)

SELECT
	Customer,
	AVG(days_review) AS avg_time_to_review
FROM
	t_days
WHERE 
	days_review IS NOT NULL
GROUP BY 
	Customer
;

-- 3. In how many cities have customers not had their order sent after placing an order

SELECT DISTINCT
	City,
 	CASE WHEN sent_date IS NULL THEN 'order not sent' ELSE 'orer_sent' END AS order_not_sent,
	purchased_date,
	`Order`,
	Customer
FROM 
	t_days
WHERE 
	sent_date IS NULL
;

-- 4. For orders sent, which % of each cities orders have not been sent out within 3 days or less

SELECT 
	City,
	SUM(CASE WHEN days_sent <= 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_orders_meeting_3_day_KPI,
	SUM(CASE WHEN days_sent <= 3 THEN 1 ELSE 0 END) AS time_to_send_kpi,
	COUNT(*) AS order_per_city
FROM t_days
GROUP BY 
	City
;

-- Question 4 - verification

SELECT 
	*,
	COUNT(*) OVER (PARTITION BY City) AS order_per_city,
	CASE WHEN days_sent <= 3 THEN 1 ELSE 0 END AS time_to_send_kpi
FROM t_days
;