-- Preppin Data
-- 2019 Week 29
-- https://preppindata.blogspot.com/2019/04/2019-week-29.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with STRING_SPLIT

-- STEP 1
-- Unpivot the data. 
-- Note: we cannot filter rows during this process because they are removed before the unpivot process, therefore eliminating necessary rows for further steps

DROP TABLE IF EXISTS #IP
SELECT
	Name,
	Packages,
	Frequency,
	value AS ind_package
INTO #IP -- Create Individual packages temporary table
FROM pd2019w29_a_Customers CROSS APPLY STRING_SPLIT(Packages,'|')
;

--SELECT * FROM #IP; -- Test

-- STEP 2
-- Enrich the frequency table with the periods

DROP TABLE IF EXISTS #eft
SELECT *,
CASE 
  WHEN f.Frequency = 'week' THEN 52
  WHEN f.Frequency = 'month' THEN 12
  WHEN f.Frequency = 'quarter' THEN 4
  WHEN f.Frequency = 'year' THEN 1
END AS packages_per_year
INTO #eft -- Enriched frequency table
FROM pd2019w29_c_SFrequency f
;

--SELECT * FROM #eft; -- Test

-- STEP 3
-- Join the other tables, calculate the annual subscription costs and the average price for the Mistery product
-- This can be done in one step. However, for clarity purposes, I will do it in two

--Step 3a. Join the other tables, calculate the annual subscription costs

DROP TABLE IF EXISTS #as_costs
SELECT
	ip.Name,
	ip.Packages,
--	Frequency,
	ip.ind_package,
	p.S_package,
	p.Product,
	p.Price,
	S_Frequency_number,
	f.Frequency,
	f.packages_per_year,
	CASE WHEN Product = 'Mystery' THEN 0 ELSE f.packages_per_year END AS packages_per_year_no_mistery,
	Price * packages_per_year AS Annual_subscription_costs
INTO #as_costs -- annual subscription costs
	FROM #IP ip
INNER JOIN dbo.pd2019w29_b_SProduct p ON
	ip.ind_package = p.S_package
INNER JOIN #eft f ON
	ip.Frequency = f.S_Frequency_number
;

--SELECT * FROM #as_costs; -- Test

-- Step 3b. Calculate the mistery product price using the weighted average 

DROP TABLE IF EXISTS #MP
SELECT
	Name,
	S_package,
	Product,
	Price,
	packages_per_year,
--	packages_per_year_no_mistery,
	Annual_subscription_costs,
	SUM(Annual_subscription_costs) OVER () / SUM(packages_per_year_no_mistery) OVER () AS Mystery_price
INTO #MP -- Mistery price
FROM #as_costs
;

--STEP 4 Aggregate to generate the resulting tables

--Step 4a - Subscription Pricing Table:
SELECT 
	AVG(S_package) AS Subscription_Package,	
	Product,
	AVG(CASE WHEN Product = 'Mystery' THEN Mystery_price ELSE Price END) AS Price
FROM #MP 
GROUP BY 
	Product
ORDER BY 
	AVG(S_package)
;

-- Step 4b - Annual Cost To Customer

SELECT 
	SUM(CASE WHEN Product = 'Mystery' THEN Mystery_price ELSE Price END * packages_per_year) AS Subscription_cost_per_annum,
	Name
FROM #MP
GROUP BY 
	Name
;