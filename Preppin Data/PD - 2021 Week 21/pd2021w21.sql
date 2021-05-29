-- Preppin Data
-- 2021 Week 21
-- https://preppindata.blogspot.com/2021/05/2021-week-21-getting-trolleyed.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Create date with MAKE_DATE
-- Split string with SPLIT_PART

--STEP 1
-- Create dates for each dataset
-- Union all the files in a temp table

DROP TABLE IF EXISTS t_unioned;
CREATE TEMPORARY TABLE t_unioned AS 
SELECT *, make_date(2021, 1 , day_of_month) as created_date FROM public.pd2021w21_month_01
UNION ALL
SELECT *, make_date(2021, 2 , day_of_month) as created_date FROM public.pd2021w21_month_02
UNION ALL
SELECT *, make_date(2021, 3 , day_of_month) as created_date FROM public.pd2021w21_month_03
UNION ALL
SELECT *, make_date(2021, 4 , day_of_month) as created_date FROM public.pd2021w21_month_04
UNION ALL
SELECT *, make_date(2021, 5 , day_of_month) as created_date FROM public.pd2021w21_month_05
UNION ALL
SELECT *, make_date(2021, 6 , day_of_month) as created_date FROM public.pd2021w21_month_06
UNION ALL
SELECT *, make_date(2021, 7 , day_of_month) as created_date FROM public.pd2021w21_month_07
UNION ALL
SELECT *, make_date(2021, 8 , day_of_month) as created_date FROM public.pd2021w21_month_08
UNION ALL
SELECT *, make_date(2021, 9 , day_of_month) as created_date FROM public.pd2021w21_month_09
UNION ALL
SELECT *, make_date(2021, 10, day_of_month) as created_date FROM public.pd2021w21_month_10
;
--SELECT * FROM t_unioned; -- Test

-- STEP 2
-- Create the new trolley inventory field
-- Only return any names before the '-' (hyphen). If a product doesn't have a hyphen return the full product name
-- Make price a numeric field

DROP TABLE IF EXISTS t_parsing;
CREATE TEMPORARY TABLE t_parsing AS
SELECT
	day_of_month,
	first_name,
	last_name,
	email,
	TRIM(split_part(product, '-', 1)) AS new_product, -- the TRIM is importnt to eliminate the blank space after the split
	CAST( REPLACE(price, '$', '') AS decimal(5,2)) AS new_price,
	destination,
	created_date,
	CASE
		WHEN created_date >= '2021-06-01' THEN TRUE
		ELSE FALSE
	END AS new_trolley_inventory
FROM
	t_unioned 
;
--SELECT * FROM t_parsing; -- Test

-- STEP 3
-- Work out the average selling price per product
-- Workout the Variance (difference) between the selling price and the average selling price

DROP TABLE IF EXISTS t_calcs;
CREATE TEMPORARY TABLE t_calcs AS
SELECT 
	*,
	AVG(new_price) OVER(PARTITION BY new_product) AS avg_price_per_product,
	new_price - AVG(new_price) OVER(PARTITION BY new_product) AS price_variance
FROM t_parsing
;
--SELECT * FROM t_calcs; -- Test

-- STEP 4
-- Rank the Variances (1 being the largest positive variance) per destination 
-- and whether the product was sold before or after the new trolley inventory project delivery

DROP TABLE IF EXISTS t_ranked;
CREATE TEMPORARY TABLE t_ranked AS
SELECT
	*,
	ROW_NUMBER() OVER (
						PARTITION BY destination, new_trolley_inventory 
						ORDER BY price_variance DESC
						) AS ranking
FROM
	t_calcs;
--SELECT * FROM t_ranked; -- Test

-- STEP 5
-- Return only ranks 1-5 

DROP TABLE IF EXISTS t_final_table;
CREATE TEMPORARY TABLE t_final_table AS
SELECT
	new_trolley_inventory as nt_inventory,
	ranking AS var_rank_by_dest,
	price_variance,
	avg_price_per_product,
	created_date,
	new_product as product,
	first_name,
	last_name,
	email,
	new_price as price,
	destination
FROM
	t_ranked
WHERE 
	ranking <= 5
--ORDER BY new_trolley_inventory, destination, ranking -- for test purposes
;

SELECT * FROM t_final_table;

-- BONUS
-- Which two products appeared more than once in the rankings 
-- and whether they were sold before or after the project delivery?

SELECT * FROM (
	SELECT
		product,
		nt_inventory,
		COUNT(*) as number_of_times
	FROM
		t_final_table
	GROUP BY 
		product,
		nt_inventory
	ORDER BY 
		COUNT(*) DESC
	) AS appearances
WHERE 
	number_of_times > 1
;