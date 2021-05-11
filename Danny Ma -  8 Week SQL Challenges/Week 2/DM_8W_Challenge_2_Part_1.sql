-- Data with Danny - 8 Week Challenge
-- Week 2
-- https://8weeksqlchallenge.com/case-study-2/

-- SQL Flavor: PostgreSQL

-- PART I. PIZZA METRICS

-- QUESTIONS
--1. How many pizzas were ordered?
--2. How many unique customer orders were made?
--3. How many successful orders were delivered by each runner?
--4. How many of each type of pizza was delivered?
--5. How many Vegetarian and Meatlovers were ordered by each customer?
--6. What was the maximum number of pizzas delivered in a single order?
--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--8. How many pizzas were delivered that had both exclusions and extras?
--9. What was the total volume of pizzas ordered for each hour of the day?
--10. What was the volume of orders for each day of the week?

-- SOLUTIONS
--1. How many pizzas were ordered?

SELECT 
	COUNT(pizza_id) AS pizzas_ordered 
FROM dm8_wk2_customer_orders_2 
;

--|pizzas_ordered|
--|--------------|
--|14            |

--2. How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT order_id) as unique_orders
FROM dm8_wk2_customer_orders_2 
;

--|unique_orders|
--|-------------|
--|10           |

--3. How many successful orders were delivered by each runner?

SELECT 
	runner_id,
	COUNT(order_id) AS delivered_orders
FROM dm8_wk2_runner_orders_2
WHERE cancellation IS NULL
GROUP BY 
	runner_id;

--|runner_id|delivered_orders|
--|---------|----------------|
--|1        |4               |
--|2        |3               |
--|3        |1               |

--4. How many of each type of pizza was delivered?

SELECT 
	pn.pizza_name,
	 COUNT(*) AS delivered_pizzas
FROM dm8_wk2_customer_orders_2 AS co
	INNER JOIN dm8_wk2_runner_orders_2 AS ro
		ON co.order_id = ro.order_id
	INNER JOIN dm8_wk2_pizza_names AS pn
		ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL -- this leaves delivered only
GROUP BY 
	pn.pizza_name
;

--|pizza_name|delivered_pizzas|
--|----------|----------------|
--|Meatlovers|9               |
--|Vegetarian|3               |

--5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
	co.customer_id,
	SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS vegetarian,
	SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers
FROM dm8_wk2_customer_orders_2 AS co
	INNER JOIN dm8_wk2_pizza_names AS pn
		ON co.pizza_id = pn.pizza_id
GROUP BY 
	co.customer_id
ORDER BY 
	co.customer_id
;

--|customer_id|vegetarian|meatlovers|
--|-----------|----------|----------|
--|101        |1         |2         |
--|102        |1         |2         |
--|103        |1         |3         |
--|104        |0         |3         |
--|105        |1         |0         |

--6. What was the maximum number of pizzas delivered in a single order?

WITH ranked_orders AS (
	SELECT 
		co.order_id,
		COUNT(*) AS delivered_pizzas,
		DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS ranked
	FROM dm8_wk2_customer_orders_2 AS co
		INNER JOIN dm8_wk2_runner_orders_2 AS ro
			ON co.order_id = ro.order_id
	WHERE 
		ro.cancellation IS NULL -- this leaves delivered only
	GROUP BY 
		co.order_id
	ORDER BY 
		COUNT(*) DESC
)
SELECT
	order_id,
	delivered_pizzas
FROM ranked_orders 
WHERE ranked = 1
;

--|order_id|delivered_pizzas|
--|--------|----------------|
--|4       |3               |

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT 
	co.customer_id,
	SUM(CASE WHEN co.exclusions IS NULL AND extras is NULL THEN 0 ELSE 1 END) AS at_least_1_change,
	SUM(CASE WHEN co.exclusions IS NULL AND extras is NULL THEN 1 ELSE 0 END) AS no_changes
FROM dm8_wk2_customer_orders_2 AS co
	INNER JOIN dm8_wk2_runner_orders_2 AS ro
		ON co.order_id = ro.order_id
WHERE 
	ro.cancellation IS NULL -- this leaves delivered only
GROUP BY
	co.customer_id
;

--|customer_id|at_least_1_change|no_changes|
--|-----------|-----------------|----------|
--|101        |0                |2         |
--|102        |0                |3         |
--|103        |3                |0         |
--|104        |2                |1         |
--|105        |1                |0         |

--8. How many pizzas were delivered that had both exclusions and extras?

SELECT
	SUM(CASE WHEN co.exclusions IS NULL OR extras IS NULL THEN 0 ELSE 1 END) AS excl_and_extras
FROM dm8_wk2_customer_orders_2 AS co
	INNER JOIN dm8_wk2_runner_orders_2 AS ro
		ON co.order_id = ro.order_id
WHERE 
	ro.cancellation IS NULL -- this leaves delivered only
;

--|excl_and_extras|
--|---------------|
--|1              |


--9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
	CAST( EXTRACT (hour from order_time) AS INT) AS hour_of_day,
	COUNT(pizza_id) AS number_of_pizzas
FROM dm8_wk2_customer_orders_2
GROUP BY 
	hour_of_day
ORDER BY 
	hour_of_day
;

--|hour_of_day|number_of_pizzas|
--|-----------|----------------|
--|11         |1               |
--|12         |2               |
--|13         |3               |
--|18         |3               |
--|19         |1               |
--|21         |3               |
--|23         |1               |

--10. What was the volume of orders for each day of the week?

SELECT
	to_char(order_time, 'Day') AS weekday,
	COUNT(distinct order_id) AS number_of_orders
FROM dm8_wk2_customer_orders_2
GROUP BY 
	EXTRACT( dow FROM order_time), 
	weekday
ORDER BY
	EXTRACT( dow FROM order_time)
;

--|weekday  |number_of_orders|
--|---------|----------------|
--|Wednesday|5               |
--|Thursday |2               |
--|Friday   |1               |
--|Saturday |2               |
