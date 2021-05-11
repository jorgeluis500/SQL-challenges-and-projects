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
	SELECT
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
;
--SELECT * FROM vw_dm8_wk2_customer_orders; -- Test

-- STEP 2. Runners orders
-- Getting the nulls right in the first
-- Removing text from the distance and duration columns
-- Placing everything in a new view

DROP VIEW IF EXISTS vw_dm8_wk2_runner_orders;
CREATE VIEW vw_dm8_wk2_runner_orders AS
WITH nulls_right AS (
	SELECT
		order_id,
		runner_id,
		CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
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
	pickup_time,
	regexp_replace(distance2, '[a-z]+', '' ) AS distance,
	regexp_replace(duration2, '[a-z]+', '' ) AS duration,
	cancellation
FROM nulls_right
;
--SELECT * FROM vw_dm8_wk2_runner_orders; -- Test



