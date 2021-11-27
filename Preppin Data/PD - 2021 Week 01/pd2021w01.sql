-- Preppin Data
-- 2021 Week 1
--https://preppindata.blogspot.com/2021/01/2021-week-1.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Date parts
-- String split


-- SOLUTION
--Split the 'Store-Bike' field into 'Store' and 'Bike'
--Clean up the 'Bike' field to leave just three values in the 'Bike' field (Mountain, Gravel, Road) 
--Create two different cuts of the date field: 'quarter' and 'day of month' 
--Remove the first 10 orders as they are test values

WITH cleaning AS (
	SELECT
		order_id,
		customer_age,
		bike_value,
		is_existing_customer,
		order_date,
		date_part('quarter', order_date) AS qt, 		--Create two different cuts of the date field: 'quarter' and 'day of month' 
		date_part('day', order_date) AS day_of_month, 	--Create two different cuts of the date field: 'quarter' and 'day of month' 
		split_part(store_bike, ' - ', 1) AS store, 		--Split the 'Store-Bike' field into 'Store' and 'Bike'
		split_part(store_bike, ' - ', 2) AS bike 		--Split the 'Store-Bike' field into 'Store' and 'Bike'
	FROM
		public.pd2021w01bike_sales_csv
	WHERE order_id > 10 								--Remove the first 10 orders as they are test values
)
SELECT
	qt,
	store,
	CASE
		WHEN LEFT(bike, 1) = 'G' THEN 'Gravel'
		WHEN LEFT(bike, 1) = 'M' THEN 'Mountain'
		WHEN LEFT(bike, 1) = 'R' THEN 'Road'
		ELSE 'Check'
	END AS bike, 				-- Clean up the 'Bike' field to leave just three values in the 'Bike' field (Mountain, Gravel, Road) 
	order_id,
	customer_age,
	bike_value,
	is_existing_customer,
	day_of_month
FROM
	cleaning
ORDER BY
	1
;
