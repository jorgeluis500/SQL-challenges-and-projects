-- Data with Danny - 8 Week Challenge
-- Week 1
-- https://8weeksqlchallenge.com/case-study-1/

-- SQL Flavor: PostgreSQL

-- QUESTIONS
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- SOLUTIONS
--1. What is the total amount each customer spent at the restaurant?

select 
	s.customer_id,
	sum(m.price) as amount_spent
from dm8_wk1_sales as s
	inner join dm8_wk1_menu as m
	on s.product_id = m.product_id
group by
	s.customer_id
;

--|customer_id|amount_spent|
--|-----------|------------|
--|B          |74          |
--|C          |36          |
--|A          |76          |

--2. How many days has each customer visited the restaurant?

select 
	customer_id,
	count(distinct order_date) as unique_days
from dm8_wk1_sales 
group by
	customer_id
;

--|customer_id|unique_days|
--|-----------|-----------|
--|A          |4          |
--|B          |6          |
--|C          |2          |

--3. What was the first item from the menu purchased by each customer?

with ranked_items as(
	select 
		*,
		RANK() over (partition by customer_id order by order_date) as items_rank 
	from dm8_wk1_sales
	
)
select distinct
	ri.customer_id,
	ri.order_date,
--	ri.product_id, -- for test purposes
--	ri.rirst_items_by_cust, -- for test purposes
	m.product_name
from ranked_items ri
	inner join dm8_wk1_menu m
	on ri.product_id = m.product_id
where items_rank = 1
order by
	customer_id,
	order_date
;

--|customer_id|order_date|product_name|
--|-----------|----------|------------|
--|A          |2021-01-01|curry       |
--|A          |2021-01-01|sushi       |
--|B          |2021-01-01|curry       |
--|C          |2021-01-01|ramen       |

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	m.product_name,
	count(*) 
from dm8_wk1_sales as s
	inner join dm8_wk1_menu as m
	on s.product_id = m.product_id
group by m.product_name
limit 1
;
--|product_name|count|
--|------------|-----|
--|ramen       |8    |

--5. Which item was the most popular for each customer?

With purchases as (
	select 
		s.customer_id,
		m.product_name,
		count(*) as times_purchased
	from dm8_wk1_sales s
		inner join dm8_wk1_menu as m
		on s.product_id = m.product_id
	group by
		s.customer_id,
		m.product_name
	order by s.customer_id, count(*) desc
)
, ranked as (
	select 
		*,
		rank() over (partition by customer_id order by times_purchased desc) as most_pop
	from purchases
)
select 
	customer_id,
	product_name,
	times_purchased
from ranked
where most_pop = 1
;

--|customer_id|product_name|times_purchased|
--|-----------|------------|---------------|
--|A          |ramen       |3              |
--|B          |sushi       |2              |
--|B          |curry       |2              |
--|B          |ramen       |2              |
--|C          |ramen       |3              |

-- 6. Which item was purchased first by the customer after they became a member?

-- At this stage it is bettter to create the a table with membership and product rankings for use in the next questions

Drop table if exists temp_membership_p_ranked;
Create temporary table temp_membership_p_ranked as 
with memb as (
	select
		s.customer_id,
		s.order_date,
		s.product_id,
		m.product_name,
		m.price,
		mb.join_date,
		case when (s.order_date >= mb.join_date) then 'Y' else 'N' end as membership
	from dm8_wk1_sales s
	left join dm8_wk1_members mb 
		on s.customer_id = mb.customer_id
	inner join dm8_wk1_menu m
		on s.product_id = m.product_id
)
select 
	*,
	rank() over (partition by customer_id, membership order by order_date) as product_rank_asc,
	rank() over (partition by customer_id, membership order by order_date desc) as product_rank_desc
from memb
;
-- SELECT * FROM temp_membership_p_ranked; -- Test

-- Answer to: Which item was purchased first by the customer after they became a member?
select
	customer_id,
	order_date,
	product_name,
	membership
from temp_membership_p_ranked
where product_rank_asc = 1 and membership = 'Y'
order by
	customer_id,
	order_date
;

--|customer_id|order_date|product_name|membership|
--|-----------|----------|------------|----------|
--|A          |2021-01-07|curry       |Y         |
--|B          |2021-01-11|sushi       |Y         |

--7. Which item was purchased just before the customer became a member?

select 
	customer_id,
	order_date,
	product_name,
	membership
from temp_membership_p_ranked
where join_date is not null -- considers member only
and product_rank_desc = 1 and membership = 'N'
order by
	customer_id,
	order_date
;

--|customer_id|order_date|product_name|membership|
--|-----------|----------|------------|----------|
--|A          |2021-01-01|curry       |N         |
--|A          |2021-01-01|sushi       |N         |
--|B          |2021-01-04|sushi       |N         |

--8. What is the total items and amount spent for each member before they became a member?

select 
	customer_id,
	count(product_id) as items,
	sum(price) as amount_spent
from temp_membership_p_ranked
where membership = 'N'
	 and join_date is not null -- considers member only
group by 
	customer_id
;

--|customer_id|items|amount_spent|
--|-----------|-----|------------|
--|A          |2    |25          |
--|B          |3    |40          |

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
	customer_id,
	sum(case when product_name = 'sushi' then (price *10 * 2) else (price * 10) end) as points
from temp_membership_p_ranked
where 
	membership = 'Y'
group by
	customer_id
;

--|customer_id|points|
--|-----------|------|
--|A          |510   |
--|B          |440   |

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January

with dates as (
	select 
		*,
		'2021-01-31' AS end_of_jan,
		join_date + 7 as first_week,
		('2021-01-31' - join_date) as member_days,
		('2021-01-31' - join_date) / 7 as member_weeks
	from temp_membership_p_ranked
	where 
		membership = 'Y'
)
SELECT 
--	*, -- For test purposes
	customer_id,
--	CASE WHEN order_date < first_week THEN 'within_1st_week' ELSE 'after_1st_week' END AS order_when, -- For test purposes
	SUM(CASE WHEN order_date < first_week THEN (price * 10 * 2) ELSE (price * 10) END ) AS points_eoj
FROM dates
group by
	customer_id
;

--|customer_id|points_eoj|
--|-----------|----------|
--|A          |1020      |
--|B          |440       |


--	BONUS QUESTIONS
-- Join All The Things (done above in Q.6)
-- Rank All the Things
	
SELECT
	customer_id,
	order_date,
	product_name,
	price,
	membership,
	CASE WHEN membership = 'Y' THEN product_rank_asc ELSE NULL END AS ranking
FROM temp_membership_p_ranked
;	

--|customer_id|order_date|product_name|price|membership|ranking|
--|-----------|----------|------------|-----|----------|-------|
--|A          |2021-01-01|curry       |15   |N         |       |
--|A          |2021-01-01|sushi       |10   |N         |       |
--|A          |2021-01-07|curry       |15   |Y         |1      |
--|A          |2021-01-10|ramen       |12   |Y         |2      |
--|A          |2021-01-11|ramen       |12   |Y         |3      |
--|A          |2021-01-11|ramen       |12   |Y         |3      |
--|B          |2021-01-01|curry       |15   |N         |       |
--|B          |2021-01-02|curry       |15   |N         |       |
--|B          |2021-01-04|sushi       |10   |N         |       |
--|B          |2021-01-11|sushi       |10   |Y         |1      |
--|B          |2021-01-16|ramen       |12   |Y         |2      |
--|B          |2021-02-01|ramen       |12   |Y         |3      |
--|C          |2021-01-01|ramen       |12   |N         |       |
--|C          |2021-01-01|ramen       |12   |N         |       |
--|C          |2021-01-07|ramen       |12   |N         |       |
