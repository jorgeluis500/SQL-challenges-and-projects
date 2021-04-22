-- Preppin Data
-- 2021 Week 15
-- https://preppindata.blogspot.com/2021/03/2021-week-15.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with unnest, array and string_to_array
-- Best way to create temporary tables: Not using INTO

-- STEP 1
-- Unpivot the menu table to have it in tabular form

DROP TABLE IF EXISTS temp_menu;
CREATE TEMPORARY TABLE temp_menu AS 
WITH Unpivoted AS (
		SELECT
			unnest(array['Pizza', 'Pasta', 'House_plate']) As meal_type,
			unnest(array[pizza,	pasta, "House Plates"]) AS meal,
			unnest(array["Pizza ID", "Pasta ID", "House Plates ID"]) AS meal_id,
			unnest(array["Pizza Price ", "Pasta Price",	"House Plates Prices"]) AS Prices
		FROM
			pd2021w15_menu_csv
)
SELECT
	*
FROM Unpivoted
WHERE
	meal IS NOT NULL
ORDER BY 
	meal_type	DESC
;
--SELECT * FROM temp_menu; -- Test

-- STEP 2
-- Unpivot the order table to get one item by line, using the string_to_array() function which splits the string by delimiter
-- Get day of the week name

DROP TABLE IF EXISTS temp_order;
CREATE TEMPORARY TABLE temp_order AS 
SELECT
	"Customer Name",
	"Order Date",
	EXTRACT (DOW FROM "Order Date") AS day_of_week, -- Returns the day of the week as a number, 0 for Sunday, 6 for Saturday
	To_Char("Order Date", 'Day') AS day_name, -- Returns the day name
	CAST( unnest(string_to_array("Order",'-')) AS INT) AS meal_id
FROM
	pd2021w15_order_csv
;
--SELECT * FROM temp_order; -- Test

-- STEP 3 
-- Join both tables
-- Get adjusted price taking into account Monday's discount

DROP TABLE IF EXISTS temp_all_combined;
CREATE TEMPORARY TABLE temp_all_combined AS 
SELECT
	o."Customer Name",
	o."Order Date",
	o.day_of_week,
	o.day_name,
	o.meal_id,
	m.meal_type,
	m.meal,
	m.prices,
	CASE WHEN day_of_week = 1 THEN (prices * 1.0 / 2) ELSE prices END AS adj_price
FROM temp_order o
INNER JOIN temp_menu m ON
	o.meal_id = m.meal_id
;
--SELECT * FROM temp_all_combined; -- Test

--STEP 4. Outputs

--a. Revenue per weekday
SELECT 
	day_name,
	SUM(adj_price) AS Revenue_per_weekday
FROM temp_all_combined
GROUP BY
	day_name
;

--b. Most Loyal Customer
SELECT 
	"Customer Name",
	COUNT(meal_id) AS count_itmes
FROM temp_all_combined
GROUP BY
		"Customer Name"
ORDER BY 
	COUNT(meal_id) DESC
LIMIT 1
;