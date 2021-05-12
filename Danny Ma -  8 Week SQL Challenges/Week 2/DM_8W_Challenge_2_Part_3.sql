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

-- First I will create a toppings table in tabular form

DROP TABLE IF EXISTS temp_toppings;
CREATE TEMPORARY TABLE temp_toppings AS 
SELECT
	pizza_id,
	CAST(UNNEST(string_to_array(toppings, ',')) AS INT) AS topping_id
FROM
	public.dm8_wk2_pizza_recipes
;
--SELECT * FROM temp_toppings; -- Test

-- Then I will use this table for everything else

SELECT
	pn.pizza_id,
	pn.pizza_name,
	pt.topping_name
FROM temp_toppings AS t
INNER JOIN dm8_wk2_pizza_names AS pn
	ON t.pizza_id = pn.pizza_id
INNER JOIN dm8_wk2_pizza_toppings AS pt
	ON t.topping_id = pt.topping_id
ORDER BY 
		pn.pizza_id
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


--3. What was the most common exclusion?


--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--	Meat Lovers
--	Meat Lovers - Exclude Beef
--	Meat Lovers - Extra Bacon
--	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


--7. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
