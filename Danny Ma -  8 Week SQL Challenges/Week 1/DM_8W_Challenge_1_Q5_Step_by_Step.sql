-- Data with Danny - 8 Week Challenge
-- Week 1
-- https://8weeksqlchallenge.com/case-study-1/

-- SQL Flavor: PostgreSQL

--QUESTION NUMBER 5 STEP BY STEP

--5. Which item was the most popular for each customer?

-- SOLUTION
-- Step 1. Join sales and menu tables to see the product names

SELECT
	s.customer_id,
	s.order_date,
	s.product_id,
	m.product_id,
	m.product_name,
	m.price
FROM
	public.dm8_wk1_sales AS s
INNER JOIN dm8_wk1_menu AS m ON
	s.product_id = m.product_id
;

--|customer_id|order_date|product_id|product_id|product_name|price|
--|-----------|----------|----------|----------|------------|-----|
--|B          |2021-01-04|1         |1         |sushi       |10   |
--|A          |2021-01-01|1         |1         |sushi       |10   |
--|B          |2021-01-11|1         |1         |sushi       |10   |
--|B          |2021-01-01|2         |2         |curry       |15   |
--|B          |2021-01-02|2         |2         |curry       |15   |
--|A          |2021-01-01|2         |2         |curry       |15   |
--|A          |2021-01-07|2         |2         |curry       |15   |
--|A          |2021-01-11|3         |3         |ramen       |12   |
--|A          |2021-01-11|3         |3         |ramen       |12   |
--|A          |2021-01-10|3         |3         |ramen       |12   |
--|B          |2021-01-16|3         |3         |ramen       |12   |
--|B          |2021-02-01|3         |3         |ramen       |12   |
--|C          |2021-01-01|3         |3         |ramen       |12   |
--|C          |2021-01-01|3         |3         |ramen       |12   |
--|C          |2021-01-07|3         |3         |ramen       |12   |


-- Step 2
-- In this step, count the items per customer.
-- To better visualize the results, we order them by customer and items (count of product_id) descending

SELECT
	s.customer_id,
	m.product_name,
	COUNT(s.product_id) AS items
FROM
	public.dm8_wk1_sales AS s
INNER JOIN dm8_wk1_menu AS m ON
	s.product_id = m.product_id
GROUP BY 
	s.customer_id,
	m.product_name
ORDER BY 
	s.customer_id,
	COUNT(s.product_id) DESC

--|customer_id|product_name|items|
--|-----------|------------|-----|
--|A          |ramen       |3    |
--|A          |curry       |2    |
--|A          |sushi       |1    |
--|B          |sushi       |2    |
--|B          |curry       |2    |
--|B          |ramen       |2    |
--|C          |ramen       |3    |

	
-- We realize that for Customer A, it is sushi, which was ordered 3 times
-- For customer B, there is a tie between sushi and curry, each one ordered twice
-- For customer C, he/she ordered only ramen, three times
;

-- Step 3
-- We need to rank those results, so we create a derived table and rank the items per customer with a Windows function.
-- We use rank and not row_number() because it takes ties into account

WITH counted_items AS (
	SELECT
		s.customer_id,
		m.product_name,
		COUNT(s.product_id) AS times_purchased
	FROM
		public.dm8_wk1_sales AS s
	INNER JOIN dm8_wk1_menu AS m ON
		s.product_id = m.product_id
	GROUP BY 
		s.customer_id,
		m.product_name
	ORDER BY 
		s.customer_id,
		COUNT(s.product_id) DESC
)
SELECT 
	*, 
	RANK() OVER (PARTITION BY customer_id ORDER BY times_purchased DESC) AS most_pop
FROM counted_items
;

--|customer_id|product_name|times_purchased|most_pop|
--|-----------|------------|---------------|--------|
--|A          |ramen       |3              |1       |
--|A          |curry       |2              |2       |
--|A          |sushi       |1              |3       |
--|B          |sushi       |2              |1       |
--|B          |curry       |2              |1       |
--|B          |ramen       |2              |1       |
--|C          |ramen       |3              |1       |

-- Step 4
-- We filter the ranked table to leave only items with rank (most popular) = 1
-- We use another table within the WITH clause

WITH counted_items AS (
	SELECT
		s.customer_id,
		m.product_name,
		COUNT(s.product_id) AS times_purchased
	FROM
		public.dm8_wk1_sales AS s
	INNER JOIN dm8_wk1_menu AS m ON
		s.product_id = m.product_id
	GROUP BY 
		s.customer_id,
		m.product_name
	ORDER BY 
		s.customer_id,
		COUNT(s.product_id) DESC
)
-- The previous query is now another derived table
, ranked AS (
	SELECT 
		*, 
		RANK() OVER (PARTITION BY customer_id ORDER BY times_purchased DESC) AS most_pop
	FROM counted_items
)
-- And we filter to leave only rank (most_pop) = 1, without selecting the column, for presentation purposes
SELECT
	customer_id,
	product_name,
	times_purchased
FROM ranked
WHERE
	most_pop = 1
;

--|customer_id|product_name|times_purchased|
--|-----------|------------|---------------|
--|A          |ramen       |3              |
--|B          |sushi       |2              |
--|B          |curry       |2              |
--|B          |ramen       |2              |
--|C          |ramen       |3              |
