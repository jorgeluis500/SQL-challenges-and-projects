-- Preppin Data
-- 2021 Week 4
-- https://preppindata.blogspot.com/2021/03/2021-week-4.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- UNION
-- Date functions

-- STEP 1
-- Union the Stores data together
-- Rename the 'Table Names' as 'Store' 

DROP TABLE IF EXISTS All_files;
CREATE TEMPORARY TABLE All_files
SELECT *, 'Birmingham' AS Store FROM preppindata.pd2021w4_birmingham
UNION ALL
SELECT *, 'Leeds' AS Store FROM preppindata.pd2021w4_leeds
UNION ALL
SELECT *, 'London' AS Store FROM preppindata.pd2021w4_london
UNION ALL
SELECT *, 'Manchester' AS Store FROM preppindata.pd2021w4_manchester
UNION ALL
SELECT *, 'York' AS Store  FROM preppindata.pd2021w4_york
;

-- STEP 2
-- Add all the products to get Products Sold column (Intermediary steps Customer type and Product were not done since they are not necessary for the final result)
-- Get the quarter from the date column

DROP TABLE IF EXISTS All_products;
CREATE TEMPORARY TABLE All_products
SELECT 
    Date,
    QUARTER(STR_TO_DATE(`Date`, '%d/%m/%Y')) AS Qtr,
    (New_Saddles + New_Mudguards + New_Wheels + New_Bags + Existing_Saddles + Existing_Mudguards + Existing_Wheels + Existing_Bags) AS Products_sold,
    Store
FROM All_files
;

-- STEP 3
-- Bring targets with a join
-- Group by Quarter and Store
-- Aggregate products quantitites and targets
-- Calculate variance to target
-- Calculate the ranks

WITH All_data AS (
	SELECT
		ap.Qtr,
		ap.Store,
		SUM(ap.Products_sold) AS Products_sold,
		ROUND(AVG(t.target)) AS Target, 
		SUM(ap.Products_sold) - ROUND(AVG(t.target)) AS Variance_to_Target
	FROM All_products ap
	INNER JOIN pd2021w4_ztargets t
		ON ap.Qtr = t.Quarter
		AND ap.Store = t.Store
	GROUP BY 
		ap.Qtr,
		ap.Store
)
SELECT 
	Qtr AS `Quarter`,
	RANK() OVER( PARTITION BY Qtr ORDER BY Variance_to_Target DESC ) AS `Rank`,
    Store,
    Products_sold,
    Target,
    Variance_to_Target
FROM All_data
;