-- Data with Danny - 8 Week Challenge
-- Week 2
-- https://8weeksqlchallenge.com/case-study-2/

-- SQL Flavor: PostgreSQL

-- FIXING THE TABLES
-- And bonus question 3
-- Create 2 database views on top of the customer_orders and the runner_orders data tables to fix up all of the data issues

-- STEP 1. Customer orders view:

DROP VIEW IF EXISTS vw_dm8_wk2_customer_orders;
CREATE VIEW vw_dm8_wk2_customer_orders AS
	SELECT DISTINCT -- Eliminates duplicated line for order_id number 4
		order_id,
		customer_id,
		pizza_id,
	--	exclusions,
		CASE
			WHEN exclusions = '' THEN NULL
			WHEN exclusions = 'null' THEN NULL
			ELSE exclusions END AS exclusions,
	--	extras,
		CASE
			WHEN extras = '' THEN NULL
			WHEN extras = 'null' THEN NULL
			ELSE extras END AS extras,
		order_time
	FROM dm8_wk2_customer_orders
	ORDER BY 
		order_id,
		customer_id,
		pizza_id
;
--SELECT * FROM vw_dm8_wk2_customer_orders; -- Test

-- STEP 2. Runners orders

-- Getting the nulls right in the first
-- Removing text from the distance and duration columns and cast them as decimal and integer
-- Cast pickup_time as timestamp
	-- Order_id number 3 has order_time of 2020-01-02 12:51:23
	-- And pickup_time of 2020-01-02 00:12:37
	-- There must be an error since pickup time should come after order time.
	-- I will assume that order_time is correct (around lunchtime) and pickup_time is 13:12:37, 13 hours later than stated in the table
-- Place everything in a new view

DROP VIEW IF EXISTS vw_dm8_wk2_runner_orders;
CREATE VIEW vw_dm8_wk2_runner_orders AS
WITH nulls_right AS (
	SELECT
		order_id,
		runner_id,
		CAST( CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS timestamp) AS pickup_time,
		CASE WHEN distance = 'null' THEN NULL ELSE distance END AS distance2,
		CASE WHEN duration = 'null' THEN NULL ELSE duration END AS duration2,
		CASE
			WHEN cancellation = 'null' THEN NULL
			WHEN cancellation = '' THEN NULL
			ELSE cancellation END AS cancellation
	FROM dm8_wk2_runner_orders
)
SELECT
	order_id,
	runner_id,
	CASE WHEN order_id = '3' THEN (pickup_time + INTERVAL '13 hour') ELSE pickup_time END AS pickup_time,
	CAST( regexp_replace(distance2, '[a-z]+', '' ) AS DECIMAL(5,2) ) AS distance_km,
	CAST( regexp_replace(duration2, '[a-z]+', '' ) AS INT ) AS duration_min,
	cancellation
FROM nulls_right
;
-- SELECT * FROM vw_dm8_wk2_runner_orders; -- Test

-- STEP 3 
-- The runners table has registration dates one year in the future. 
-- I will create a view to correct it

DROP VIEW IF EXISTS vw_dm8_wk2_runners;
CREATE VIEW vw_dm8_wk2_runners AS 
SELECT
	runner_id,
--	registration_date,
	CAST( registration_date + INTERVAL '-1 year' AS date) AS registration_date
FROM
	public.dm8_wk2_runners
;
--SELECT * FROM vw_dm8_wk2_runners; -- Test


