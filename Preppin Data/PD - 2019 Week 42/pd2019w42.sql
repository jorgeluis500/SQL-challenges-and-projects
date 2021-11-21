-- Preppin Data
-- 2019 Week 42
-- https://preppindata.blogspot.com/2019/11/2019-week-42.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Split strings with split_part
-- Subbstring match
-- Trim text
-- 

-- STEP 1 
-- Split location into Cities and Countries
-- Check spellling of cities and countries
-- Split sales and const into numbers and currencies

DROP TABLE IF EXISTS 	t_cleaning ;
CREATE TEMPORARY TABLE 	t_cleaning AS
WITH string_split AS (
	SELECT
		TRIM(split_part("Location",',',1)) AS city,
		TRIM(split_part("Location",',',2)) AS country,
		potential_store_location,
		CAST( TRIM(split_part(store_potential_sales, ' ', 1)) AS INT) AS store_potential_sales_amount,
		TRIM(split_part(store_potential_sales, ' ', 2)) AS store_potential_sales_currency,
		CAST( TRIM(split_part(store_cost, ' ', 1)) AS INT) store_potential_cost_amount,
		TRIM(split_part(store_cost, ' ', 2)) AS store_potential_cost_currency
	FROM
		public.pd2019w42_potential_csv
	ORDER BY
		1
)
SELECT
	*,
	(city = 'Miami') OR (city = 'Monterrey') OR (city = 'New York') OR (city = 'San Francisco') AS valid_city,
	(country = 'United States') OR (country = 'Mexico') AS valid_country,
	(store_potential_sales_amount > store_potential_cost_amount) AS sales_greater_than_cost
FROM string_split
;

--SELECT * FROM t_cleaning ; -- Test

-- Test
--Are there more than one zip code?

--SELECT * FROM t_cleaning ORDER BY 3; -- Test
--
--SELECT
--	COUNT(*) AS records,
--	count(DISTINCT potential_store_location) AS unique_zips
--FROM
--	t_cleaning
--;
--|records|unique_zips|
--|-------|-----------|
--|20     |15         |


-- STEP 2
-- Leave only valid cities and countries
-- Rank cities by sales per zip. We only want the store per zip code that could the most sales
-- Remove any instances where the Store Cost is higher than Potential Store Sales

DROP TABLE IF EXISTS 	t_all_fields;
CREATE TEMPORARY TABLE 	t_all_fields AS
WITH ranked_sales AS (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY potential_store_location ORDER BY store_potential_sales_amount DESC) AS sales_rank -- Rank cities by sales per zip
	FROM
		t_cleaning
	WHERE valid_city AND valid_country -- Leave only valid cities and countries. These are booleans
)
SELECT
	*
FROM
	ranked_sales
WHERE
	sales_rank = 1 -- We only want the store per zip code that could the most sales
	AND store_potential_sales_amount > store_potential_cost_amount -- Remove any instances where the Store Cost is higher than Potential Store Sales
;

SELECT
	af.city,
	af.country,
	af.potential_store_location AS zip_code,
	af.store_potential_cost_amount AS store_cost,
	af.store_potential_sales_amount AS store_potential_sales,
	af.store_potential_sales_currency AS currency,
	CAST(cc.value_in_usd AS decimal(5,2)) AS value_in_usd
FROM
	t_all_fields AS af
LEFT JOIN pd2019w42_currency_conversion AS cc 
	ON af.store_potential_sales_currency = cc.currency
;
