-- Data with Danny - 8 Week Challenge
-- Week 2
-- https://8weeksqlchallenge.com/case-study-2/

-- SQL Flavor: PostgreSQL

-- PART III. INGREDIENT OPTIMISATION

--QUESTIONS
--1. What are the standard ingredients for each pizza?
--2. What was the most commonly added extra?
--3. What was the most common exclusion?
--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--	Meat Lovers
--	Meat Lovers - Exclude Beef
--	Meat Lovers - Extra Bacon
--	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--7. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

--SOLUTIONS
--1. What are the standard ingredients for each pizza?

-- First we create a toppings table in tabular form and with toppings' names

DROP TABLE IF EXISTS temp_toppings;
CREATE TEMPORARY TABLE temp_toppings AS
WITH toppings_in_col AS(
	SELECT
		pizza_id,
		CAST(UNNEST(string_to_array(toppings, ',')) AS INT) AS topping_id
	FROM public.dm8_wk2_pizza_recipes
)
SELECT
	tc.pizza_id,
	tc.topping_id,
	pt.topping_name
FROM toppings_in_col AS tc
INNER JOIN dm8_wk2_pizza_toppings AS pt
	ON tc.topping_id = pt.topping_id
;
SELECT * FROM temp_toppings; -- Test

-- Then we use this table to bring the toppings names
-- We store this information in a temp tamble since it will be useful for question 5

DROP TABLE IF EXISTS temp_pizza_w_ing;
CREATE TEMPORARY TABLE temp_pizza_w_ing AS
SELECT
	pn.pizza_id,
	pn.pizza_name,
	t.topping_name
FROM temp_toppings AS t
INNER JOIN dm8_wk2_pizza_names AS pn
	ON t.pizza_id = pn.pizza_id
ORDER BY 
		pn.pizza_id
;
SELECT * FROM temp_pizza_w_ing
;

--|pizza_id|pizza_name|topping_name|
--|--------|----------|------------|
--|1       |Meatlovers|BBQ Sauce   |
--|1       |Meatlovers|Pepperoni   |
--|1       |Meatlovers|Cheese      |
--|1       |Meatlovers|Salami      |
--|1       |Meatlovers|Chicken     |
--|1       |Meatlovers|Bacon       |
--|1       |Meatlovers|Mushrooms   |
--|1       |Meatlovers|Beef        |
--|2       |Vegetarian|Tomato Sauce|
--|2       |Vegetarian|Cheese      |
--|2       |Vegetarian|Mushrooms   |
--|2       |Vegetarian|Onions      |
--|2       |Vegetarian|Peppers     |
--|2       |Vegetarian|Tomatoes    |


-- What are the common ingredients in each pizza? (if the question means this)

	SELECT
		pt.topping_id,
		pt.topping_name
	FROM temp_toppings AS t
	INNER JOIN dm8_wk2_pizza_toppings AS pt
		ON t.topping_id = pt.topping_id 
	WHERE t.pizza_id = 1
INTERSECT
	SELECT
		pt.topping_id,
		pt.topping_name
	FROM temp_toppings AS t
	INNER JOIN dm8_wk2_pizza_toppings AS pt
		ON t.topping_id = pt.topping_id 
	WHERE t.pizza_id = 2
;

--|topping_id|topping_name|
--|----------|------------|
--|4         |Cheese      |
--|6         |Mushrooms   |

--2. What was the most commonly added extra?

--a. First I will split the extras into one per column
-- The way to do it is to unpivot (with UNNEST) the resulting array from str_to_array. 
-- For it to work, you need to replace the NULLs with 0's using COALESCE
-- I leave all the columns to check how everything works. In a real life case, I would remove it to query only necessary data

WITH split_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		extras,
		CAST(UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT) AS extras_col,
		order_time
	FROM
		vw_dm8_wk2_customer_orders
)

-- In this step we bring the ingredients' names. The INNER JOIN removes the 0's

SELECT 
	topping_name AS added_topping,
	COUNT(*) AS number_of_times 
FROM split_orders AS so
INNER JOIN dm8_wk2_pizza_toppings AS pt
	ON so.extras_col = pt.topping_id
GROUP BY
	topping_name
ORDER BY
	COUNT(*) DESC
LIMIT 1
;

--|added_topping|number_of_times|
--|-------------|---------------|
--|Bacon        |4              |

--3. What was the most common exclusion?

--a. First I will split the exclusion into one per column
-- The way to do it is to unpivot (with UNNEST) the resulting array from str_to_array. 
-- For it to work, you need to replace the NULLs with 0's using COALESCE
-- I leave all the columns to check how everything works. In a real life case, I would remove it to query only necessary data

WITH split_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		CAST(UNNEST(string_to_array(COALESCE(exclusions, '0'), ',')) AS INT) AS exclusions_col,
		extras,
		order_time
	FROM
		vw_dm8_wk2_customer_orders
)

-- In this step we bring the ingredients' names. The INNER JOIN removes the 0's

SELECT 
	topping_name AS excluded_topping,
	COUNT(*) AS number_of_times 
FROM split_orders AS so
INNER JOIN dm8_wk2_pizza_toppings AS pt
	ON so.exclusions_col = pt.topping_id
GROUP BY
	topping_name
ORDER BY
	COUNT(*) DESC
LIMIT 1
;

--|excluded_topping|number_of_times|
--|----------------|---------------|
--|Cheese          |3              |

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--	Meat Lovers
--	Meat Lovers - Exclude Beef
--	Meat Lovers - Extra Bacon
--	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- Step 1
-- Unpivot the extras and exclusions columns from the orders view

DROP TABLE IF EXISTS temp_unpivoted_orders;
CREATE TEMPORARY TABLE temp_unpivoted_orders AS 
SELECT
	order_id,
	customer_id,
	pizza_id,
	exclusions,
	CAST(UNNEST(string_to_array(COALESCE(exclusions, '0'), ',')) AS INT) AS exclusions_col,
	extras,
	CAST(UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT) AS extras_col,
	order_time
FROM vw_dm8_wk2_customer_orders
;
--SELECT * FROM temp_unpivoted_orders; -- Test

-- Step 2
-- Bring pizza names

DROP TABLE IF EXISTS temp_pizzas_names_ee; -- with extras and exclusions id's
CREATE TEMPORARY TABLE temp_pizzas_names_ee  AS
SELECT
	uo.order_id,
	pn.pizza_name,
	uo.pizza_id,
	COALESCE(uo.exclusions_col, 0) AS exclusions_col,
	COALESCE(uo.extras_col, 0) AS extras_col
FROM temp_unpivoted_orders AS uo
LEFT JOIN dm8_wk2_pizza_names AS pn
	ON uo.pizza_id = pn.pizza_id
;
SELECT * FROM temp_pizzas_names_ee; -- Test

-- Step 3. 
-- Bring exclusion and extras topping names to the pizza name table
-- This table will be used in the next questions

DROP TABLE IF EXISTS temp_pizzas_names_ee2; -- with extras and exclusions names
CREATE TEMPORARY TABLE temp_pizzas_names_ee2  AS
SELECT
	n.order_id,
	n.pizza_id,
	n.pizza_name,
	pt1.topping_name AS Exclusions, 
	pt2.topping_name AS Extras
FROM temp_pizzas_names_ee AS n
LEFT JOIN dm8_wk2_pizza_toppings AS pt1
	ON n.exclusions_col = pt1.topping_id
LEFT JOIN dm8_wk2_pizza_toppings AS pt2
	ON n.extras_col = pt2.topping_id
;
SELECT * FROM temp_pizzas_names_ee2; -- Test

-- Step 4
-- Aggregate the exclusions and extras using the string_agg function and GROUP BY at the bottom
-- In the second and third queries, concatenate the relevant columns

WITH all_names AS (
	SELECT
		n.order_id,
		n.pizza_id,
		n.pizza_name,
		string_agg(pt1.topping_name, ', ') AS Exclusions, 
		string_agg(pt2.topping_name, ', ') AS Extras
	FROM temp_pizzas_names_ee AS n
	LEFT JOIN dm8_wk2_pizza_toppings AS pt1
		ON n.exclusions_col = pt1.topping_id
	LEFT JOIN dm8_wk2_pizza_toppings AS pt2
		ON n.extras_col = pt2.topping_id
	GROUP BY
		n.order_id,
		n.pizza_id,
		n.pizza_name
	--ORDER BY -- for test purposes
	--	n.order_id,
	--	n.pizza_id
)
, first_concat AS (
	SELECT
		order_id,
		pizza_id,
		pizza_name,
		CASE WHEN exclusions IS NULL THEN '' ELSE ' - Excludes ' || exclusions END AS exclusions,
		CASE WHEN extras IS NULL THEN '' ELSE ' - Extra ' || extras END AS extras
	FROM all_names
)
SELECT 
	order_id,
	pizza_name || exclusions || extras AS pizzas
FROM first_concat
ORDER BY
	order_id
;

--|order_id|pizzas                                                          |
--|--------|----------------------------------------------------------------|
--|1       |Meatlovers                                                      |
--|2       |Meatlovers                                                      |
--|3       |Vegetarian                                                      |
--|3       |Meatlovers                                                      |
--|4       |Vegetarian - Excludes Cheese                                    |
--|4       |Meatlovers - Excludes Cheese                                    |
--|5       |Meatlovers - Extra Bacon                                        |
--|6       |Vegetarian                                                      |
--|7       |Vegetarian - Extra Bacon                                        |
--|8       |Meatlovers                                                      |
--|9       |Meatlovers - Excludes Cheese - Extra Bacon, Chicken             |
--|10      |Meatlovers - Excludes BBQ Sauce, Mushrooms - Extra Bacon, Cheese|


--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- We need 3 order tables: pizzas with names and standard ingredients, pizzas with names and exclusions and pizzas with names and extras
-- We have the order table with the exclusions and extras. This table has the advantage of having the pizza names in it.
-- We also have the pizzas id's in a table with the standard ingredients

-- Step 1
-- For the pizzas with standard ingredientes, we join the orders table with exclusion and inclusions table since it already has the pizza names in it.
-- Orders and pizzas with all standard ingredients

DROP TABLE IF EXISTS p_std;
CREATE TEMP TABLE p_std AS 
SELECT DISTINCT
	pn.order_id,
	pn.pizza_id,
	pn.pizza_name,
	ing.topping_name
FROM temp_pizzas_names_ee2 AS pn
INNER JOIN temp_pizza_w_ing AS ing
	ON pn.pizza_id = ing.pizza_id
ORDER BY 
	pn.order_id,
	pn.pizza_id,
	topping_name
;
--SELECT * FROM p_std; -- Test

-- Step 2
-- Orders and pizzas with Exclusions. It already exists (exclusions and extras), we select only the exclusions

DROP TABLE IF EXISTS p_exc;
CREATE TEMP TABLE p_exc AS
SELECT
	order_id,
	pizza_id,
	pizza_name,
	exclusions
FROM temp_pizzas_names_ee2
WHERE 
	exclusions IS NOT NULL;
ORDER BY 
	order_id,
	pizza_id
;
--SELECT * FROM p_exc; -- Test

-- Step 3
-- Orders and pizzas with Extras. It already exists (exclusions and extras), we select only the extras

DROP TABLE IF EXISTS p_ext;
CREATE TEMP TABLE p_ext AS
SELECT
	order_id,
	pizza_id,
	pizza_name,
	extras
FROM temp_pizzas_names_ee2
WHERE 
	extras IS NOT NULL
ORDER BY 
	order_id,
	pizza_id;
;
--SELECT * FROM p_ext; -- Test

-- Step 4
-- Now we use Set operators to include or exclude the ingredients we want:

DROP TABLE IF EXISTS all_pizzas;
CREATE TEMPORARY TABLE all_pizzas AS
SELECT * FROM p_std
EXCEPT
SELECT * FROM p_exc
UNION ALL
SELECT * FROM p_ext
;
--SELECT * FROM all_pizzas;

-- Step 5
-- We count the ingredients in each pizza, parse, concatenate and group the results

WITH ing_count AS(
	SELECT
		order_id,
		pizza_id,
		pizza_name,
		topping_name,
		COUNT(*) AS times
	FROM all_pizzas
	GROUP BY 
		order_id,
		pizza_id,
		pizza_name,
		topping_name
	ORDER BY 
		order_id,
		pizza_id,
		pizza_name,
		COUNT(*) DESC
)

, parsing AS (
SELECT
		order_id,
		pizza_id,
		pizza_name,
		CASE WHEN times = 1 THEN '' ELSE to_char(times, '9') END AS times2,
		CASE WHEN times > 1 THEN 'x' ELSE '' END AS times_ind,
		topping_name 
	FROM ing_count 
)

, concatenation AS (
	SELECT
		order_id,
		pizza_id,
		pizza_name,
		times2 || times_ind || topping_name AS topping_str
	FROM parsing
)

, grouping_all AS (
	SELECT
		order_id,
		pizza_id,
		pizza_name, 
		STRING_AGG(topping_str, ', ') AS all_ing
	FROM concatenation
	GROUP BY 
		order_id,
		pizza_id,
		pizza_name
)
--Concatenation 2
SELECT
	order_id,
	pizza_name || ': ' || all_ing AS pizza_list
FROM grouping_all
;
 
--|order_id|pizza_list                                                                          |
--|--------|------------------------------------------------------------------------------------|
--|1       |Meatlovers: BBQ Sauce, Beef, Pepperoni, Chicken, Bacon, Mushrooms, Cheese, Salami   |
--|2       |Meatlovers: Salami, Mushrooms, BBQ Sauce, Beef, Cheese, Pepperoni, Bacon, Chicken   |
--|3       |Meatlovers: BBQ Sauce, Mushrooms, Cheese, Pepperoni, Salami, Chicken, Beef, Bacon   |
--|3       |Vegetarian: Onions, Cheese, Tomato Sauce, Tomatoes, Peppers, Mushrooms              |
--|4       |Meatlovers: Pepperoni, Salami, Chicken, BBQ Sauce, Beef, Bacon, Mushrooms           |
--|4       |Vegetarian: Mushrooms, Onions, Tomato Sauce, Tomatoes, Peppers                      |
--|5       |Meatlovers:  2xBacon, Beef, Mushrooms, BBQ Sauce, Salami, Chicken, Pepperoni, Cheese|
--|6       |Vegetarian: Tomato Sauce, Peppers, Tomatoes, Onions, Cheese, Mushrooms              |
--|7       |Vegetarian: Tomatoes, Mushrooms, Peppers, Cheese, Tomato Sauce, Bacon, Onions       |
--|8       |Meatlovers: Beef, Pepperoni, Bacon, Chicken, Mushrooms, Salami, BBQ Sauce, Cheese   |
--|9       |Meatlovers:  2xBacon,  2xChicken, Salami, BBQ Sauce, Pepperoni, Mushrooms, Beef     |
--|10      |Meatlovers:  2xBacon,  2xCheese, Salami, Chicken, Pepperoni, Beef                   |


--7. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

--We use the table created in the previous question

SELECT 
	topping_name,
	COUNT(*) as times_used
FROM all_pizzas
GROUP BY 
	topping_name
ORDER BY 
	COUNT(*) DESC
;

--|topping_name|times_used|
--|------------|----------|
--|Bacon       |12        |
--|Mushrooms   |11        |
--|Cheese      |10        |
--|Chicken     |9         |
--|Pepperoni   |8         |
--|Salami      |8         |
--|Beef        |8         |
--|BBQ Sauce   |7         |
--|Tomato Sauce|4         |
--|Onions      |4         |
--|Tomatoes    |4         |
--|Peppers     |4         |
