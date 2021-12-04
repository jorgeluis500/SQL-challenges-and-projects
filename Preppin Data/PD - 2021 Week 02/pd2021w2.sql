-- Preppin Data
-- 2021 Week 2
-- https://preppindata.blogspot.com/2021/01/2021-week-2.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Extract text only with substring and regex 
-- Aggregations


-- STEP 1
-- Clean up the Model field to leave only the letters to represent the Brand of the bike
-- Workout the Order Value using Value per Bike and Quantity.
-- Calculate Days to ship by measuring the difference between when an order was placed and when it was shipped as 'Days to Ship'

DROP TABLE IF EXISTS 	t_cleaning ;
CREATE TEMPORARY TABLE 	t_cleaning  AS
SELECT
	"Bike Type",
	store,
	"Order Date",
	"Shipping Date",
	quantity,
	"Value per Bike",
	quantity * "Value per Bike" AS order_value, 	-- Workout the Order Value using Value per Bike and Quantity.
	model,
	substring(model, '([[:alpha:]]+)') AS brand, -- Clean up the Model field to leave only the letters to represent the Brand of the bike
	"Shipping Date" - "Order Date" AS days_to_ship
FROM
	pd2021w02_bike_sales
;

--SELECT * FROM t_cleaning ; -- Test

-- STEP 2 - TABLE 1
-- Aggregate Value per Bike, Order Value and Quantity by Brand and Bike Type to form:
-- 	Quantity Sold
-- 	Order Value
-- 	Average Value Sold per Brand, Type

SELECT
	brand,
	"Bike Type",
	sum(quantity) AS quantity_sold,
	sum(order_value) AS total_order_value,
	round(avg("Value per Bike"), 1) AS avg_bike_value_sold_per_brand_type
FROM
	t_cleaning
GROUP BY
	1,2
;

-- STEP 3 - TABLE 2
--	Aggregate Order Value, Quantity and Days to Ship by Brand and Store to form:
--	Total Quantity Sold
--	Total Order Value
--	Average Days to Ship

SELECT
	brand,
	store,
	sum(order_value) AS total_order_value,
	sum(quantity) AS quantity_sold,
	round(avg(days_to_ship),1) AS avg_days_to_ship
FROM
	t_cleaning 
GROUP BY
	1,2
;