-- Data with Danny - 8 Week Challenge
-- Week 2
-- https://8weeksqlchallenge.com/case-study-2/

-- SQL Flavor: PostgreSQL

-- PART II. RUNNER AND CUSTOMER EXPERIENCE

--QUESTIONS
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
--4. What was the average distance travelled for each customer?
--5. What was the difference between the longest and shortest delivery times for all orders?
--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
--7. What is the successful delivery percentage for each runner?

-- SOLUTIONS
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

-- It can have several interpretations. In mine, I get the last pickup date for each runner,
-- and I assume they have been active from their registration date to their last pickup date
-- Then the last_pickup date is substracted from their registration date and divided by 7
-- That's how many weeks they have been active

SELECT 
	ro.runner_id,
	CAST( MAX(ro.pickup_time) AS date) AS last_pickup_date,
	r.registration_date,
	CAST( MAX(ro.pickup_time) AS date) - r.registration_date as days_active,
	ROUND((CAST( MAX(ro.pickup_time) AS date) - r.registration_date) * 1.0 / 7,1) as weeks
FROM vw_dm8_wk2_runner_orders AS ro
INNER JOIN vw_dm8_wk2_runners AS r
	ON ro.runner_id = r.runner_id
GROUP BY 
	ro.runner_id,
	r.registration_date
ORDER BY 
	ro.runner_id
;

--|runner_id|last_pickup_date|registration_date|days_active|weeks|
--|---------|----------------|-----------------|-----------|-----|
--|1        |2020-01-11      |2020-01-01       |10         |1.4  |
--|2        |2020-01-10      |2020-01-03       |7          |1.0  |
--|3        |2020-01-08      |2020-01-08       |0          |0.0  |

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

-- For order_id number 3, instead of the original 2020-01-02 12:51:23, I assumed 13:12:37, 13 hours later than stated in the table
-- This gives me around 21 min after order_time, around lunch time

-- The first query involves several timestamp calculations to practice and check different methods

WITH times AS (
	SELECT DISTINCT -- to get unique orders
		co.order_id,
		co.order_time,
		ro.pickup_time,
		ro.pickup_time - co.order_time as time_raw,
		date_part('minute', (ro.pickup_time - co.order_time))  as minutes,
		date_part('second', (ro.pickup_time - co.order_time)) as seconds,
		(date_part('second', (ro.pickup_time - co.order_time)) / 60) as seconds_in_min,
		date_part('minute', (ro.pickup_time - co.order_time)) + (date_part('second', (ro.pickup_time - co.order_time)) / 60) AS min_decimal,
		(date_part('minute', (ro.pickup_time - co.order_time)) * 60) + date_part('second', (ro.pickup_time - co.order_time)) as total_seconds,
		ro.runner_id,
		ro.cancellation
	FROM vw_dm8_wk2_customer_orders AS co
	INNER JOIN vw_dm8_wk2_runner_orders AS ro
		ON co.order_id = ro.order_id
	WHERE ro.cancellation IS NULL
)
SELECT 
	runner_id,
--	CAST( (AVG(total_seconds) / 60.0) AS DECIMAL (4,1)) as avg_total_seconds, -- to compare
	CAST( AVG(min_decimal) AS DECIMAL (4,1)) AS avg_time_to_arrive
FROM times
GROUP BY
	runner_id
;

--|runner_id|avg_time_to_arrive|
--|---------|------------------|
--|1        |14.3              |
--|2        |20.0              |
--|3        |10.5              |

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- Using the same time calculation as in the previous question:

SELECT  
	co.order_id,
	COUNT(co.pizza_id) as number_of_pizzas,
	CAST( date_part('minute', (ro.pickup_time - co.order_time)) + (date_part('second', (ro.pickup_time - co.order_time)) / 60) AS decimal (4,1)) AS time_to_prepare
FROM vw_dm8_wk2_customer_orders AS co
INNER JOIN vw_dm8_wk2_runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY
	co.order_id,
	time_to_prepare
ORDER BY
	COUNT(co.pizza_id) 
;

--|order_id|number_of_pizzas|time_to_prepare|
--|--------|----------------|---------------|
--|1       |1               |10.5           |
--|2       |1               |10.0           |
--|5       |1               |10.5           |
--|7       |1               |10.3           |
--|8       |1               |20.5           |
--|3       |2               |21.2           |
--|10      |2               |15.5           |
--|4       |3               |29.3           |

-- Yes, there is a correlation between the number of pizzas in an order and the time to prepare (pickup_time)

--4. What was the average distance travelled for each customer?

--SELECT DISTINCT
--	co.customer_id,
--	ro.distance
--FROM vw_dm8_wk2_customer_orders AS co
--INNER JOIN vw_dm8_wk2_runner_orders AS ro
--	ON co.order_id = ro.order_id
--WHERE ro.cancellation IS NULL
--;

-- There must be an error, and the question probably is: What was the average distance travelled for each RUNNER?

SELECT 
	runner_id,
	ROUND(AVG(distance_km),1) AS avg_distance_km
FROM vw_dm8_wk2_runner_orders
WHERE cancellation IS NULL
GROUP BY
	runner_id
;

--|runner_id|avg_distance_km|
--|---------|---------------|
--|1        |15.9           |
--|2        |23.9           |
--|3        |10.0           |

--5. What was the difference between the longest and shortest delivery times for all orders?

WITH min_max AS (
	SELECT 
		MAX(duration_min) AS max_duration,
		MIN(duration_min) AS min_duration
	FROM vw_dm8_wk2_runner_orders
	WHERE cancellation IS NULL
)
SELECT 
	 (max_duration - min_duration) AS duration_maxmin_difference
FROM min_max
;

--|duration_maxmin_difference|
--|--------------------------|
--|30                        |

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
	runner_id,
	order_id,
--	distance_km,
--	duration_min,
--	duration_min/60.0 as duration_hr,
	ROUND((distance_km) / (duration_min /60.0), 1) AS avg_speed_km_hr
FROM vw_dm8_wk2_runner_orders 
WHERE cancellation IS NULL
ORDER BY 
	runner_id,
	order_id
;

--Yes, generaly, the speed increased with each order for runner 1 and especially for runner 2

--|runner_id|order_id|avg_speed_km_hr|
--|---------|--------|---------------|
--|1        |1       |37.5           |
--|1        |2       |44.4           |
--|1        |3       |40.2           |
--|1        |10      |60.0           |
--|2        |4       |35.1           |
--|2        |7       |60.0           |
--|2        |8       |93.6           |
--|3        |5       |40.0           |


--7. What is the successful delivery percentage for each runner?

SELECT 
	runner_id,
	COUNT(*) as all_deliveries,
	COUNT(pickup_time) as succesuful_deliveries,
	TO_CHAR(COUNT(pickup_time) *100.0 / COUNT(*), '999D9%') as succesuful_pct	
FROM vw_dm8_wk2_runner_orders
GROUP BY
	runner_id
ORDER BY 
	runner_id
;

--|runner_id|all_deliveries|succesuful_deliveries|succesuful_pct|
--|---------|--------------|---------------------|--------------|
--|1        |4             |4                    | 100.0%       |
--|2        |4             |3                    |  75.0%       |
--|3        |2             |1                    |  50.0%       |
