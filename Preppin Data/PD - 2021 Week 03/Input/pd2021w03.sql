-- Preppin Data
-- 2021 Week 3
-- https://preppindata.blogspot.com/2021/01/2021-week-3.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Union
-- Unpivoting with UNNEST and ARRAY
-- Date parsing
-- String split

-- STEP 1
-- Input the data source by pulling together all the tables

DROP TABLE IF EXISTS 	t_unioned ;
CREATE TEMPORARY TABLE 	t_unioned AS
SELECT *, 'birmingham' AS store FROM pd2021w03_birmingham_csv
UNION ALL
SELECT *, 'leeds' AS store  FROM pd2021w03_leeds_csv
UNION ALL
SELECT *, 'london'AS store  FROM pd2021w03_london_csv
UNION ALL
SELECT *, 'manchester' AS store  FROM  pd2021w03_manchester_csv
UNION ALL
SELECT *, 'york' AS store  FROM pd2021w03_york_csv
;
--SELECT * FROM t_unioned; -- Test

-- STEP 2
-- Unpivot the table by store and dates

DROP TABLE IF EXISTS 	t_unpivoted ;
CREATE TEMPORARY TABLE 	t_unpivoted AS
SELECT
	"Date",
	store,
	UNNEST(ARRAY['New - Saddles','New - Mudguards','New - Wheels','New - Bags','Existing - Saddles','Existing - Mudguards','Existing - Wheels','Existing - Bags']) AS  products,
	UNNEST(ARRAY["New - Saddles","New - Mudguards","New - Wheels","New - Bags","Existing - Saddles","Existing - Mudguards","Existing - Wheels","Existing - Bags"]) AS  products_sold
FROM t_unioned
;
--SELECT * FROM t_unpivoted; -- Test

-- STEP 3
-- Parse dates
-- Get quarter
-- Split products into Customer type and Product

DROP TABLE IF EXISTS 	t_parsed ;
CREATE TEMPORARY TABLE 	t_parsed AS
SELECT
	to_date("Date", 'dd/mm/yyyy') AS date_parsed,
	date_part('quarter', to_date("Date", 'dd/mm/yyyy')) AS qtr,
	split_part(products,' - ', 1) AS customer_type,
	split_part(products,' - ', 2) AS product,
	store,
	products_sold
FROM t_unpivoted
;

-- STEP 4a
-- Aggregate to form output of the number of products sold by: 
	-- Product, Quarter

SELECT
	product,
	qtr,
	SUM(products_sold) AS products_sold
FROM t_parsed
GROUP BY 1,2
;

-- STEP 4b
-- Aggregate to form output of the number of products sold by: 
	-- Store, Customer Type, Product

SELECT
	store,
	customer_type,
	product,
	SUM(products_sold) AS products_sold
FROM t_parsed
GROUP BY 1,2,3
;

