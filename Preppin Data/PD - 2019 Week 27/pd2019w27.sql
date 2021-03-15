-- Preppin Data
-- 2019 Week 27
-- https://preppindata.blogspot.com/2019/04/2019-week-27.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- CONVERT
-- Window Functions
-- WITH Clause (Instead of temp tables)

-- STEP 1 
-- Fix the date since it had to be imported as string

WITH Date_fixed AS 
	(
	SELECT 
		Store,
		CONVERT(date, [Date], 103) AS New_date,
		Value
	FROM dbo.pd2019w27
	)

-- STEP 2
-- With the new date fixed, add the periods

, Periods_added AS 
	(
	SELECT 
		*,
		CASE WHEN New_date <= '2019-02-14' THEN 'Pre'
			WHEN New_date > '2019-02-14' THEN 'Post'
		ELSE 'Check' END AS 'Pre_Post_Valentine_days'
	FROM Date_fixed
	)

-- STEP 3
-- Calculate the running sums with Window functions

SELECT 
	Pre_Post_Valentine_days,
	Store,
	New_date,
	SUM(Value) OVER (PARTITION BY Store, Pre_Post_Valentine_days ORDER BY New_date ASC) AS Running_Total_Sales,
	Value AS Daily_Store_Sales
FROM Periods_added
ORDER BY 
	Pre_Post_Valentine_days,
	Store,
	New_date
;