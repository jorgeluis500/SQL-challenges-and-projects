-- Preppin Data
-- 2019 Week 12
-- https://preppindata.blogspot.com/2019/04/2019-week-12.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Date conversion 
-- Window Functions
-- Time and formatting

USE PreppinData;

-- Exploration
SELECT * FROM dbo.pd2019w12a;
SELECT * FROM dbo.pd2019w12b;

-- STEP 0
-- Fix the values in the manual table
--UPDATE dbo.pd2019w12b
--SET Error = 'Planned Outage'
--WHERE Error = 'Planed Outage'
;

-- STEP 1 
-- Create a dates, times and datetime both tables
-- Create a table with all the records by uising a union.

DROP TABLE IF EXISTS #union_table

	SELECT 
		'Automatic Error log' AS Error_source,
		CONVERT(date, Start_Date_and_Time) AS Start_Date,
		CONVERT(time, Start_Date_and_Time) AS Start_Time,
		CONVERT(date, End_Date_and_Time) AS End_Date,
		CONVERT(time, End_Date_and_Time) AS End_Time,
		Start_Date_and_Time, 
		End_Date_and_Time, 
		System,
		Error
	INTO #union_table
	FROM dbo.pd2019w12a
UNION
	SELECT 
		'Manual capture error list' AS Error_source,
		Start_date,
		Start_time,
		End_date,
		End_time,
		CONVERT(varchar, Concat(Start_Date, ' ', Start_Time),121) AS Start_Date_and_Time,
		CONVERT(varchar, Concat(End_Date, ' ', End_Time),121) AS End_Date_and_Time,
		System,
		Error
	FROM dbo.pd2019w12b
;
-- Test
-- SELECT * FROM #union_table;

-- STEP 2 
-- Rank the incidents in a new temp table
-- Calculate the downtimes
-- Create error category

DROP TABLE IF EXISTS #ranked
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY Start_Date ORDER BY Start_Date, Error_source) AS Issue_rank,
	DATEDIFF(minute, Start_Date_and_Time, End_Date_and_Time)/60.0 AS Downtime_in_hours,
	CASE WHEN Error = 'Planned Outage' Then 'Planned'ELSE 'Other' END AS Error_category
INTO #ranked
FROM #union_table
-- Test
-- SELECT * FROM #ranked;

-- STEP 3
-- Select and format the relevant fields

SELECT 
	FORMAT(Downtime_in_hours / SUM(Downtime_in_hours) OVER (PARTITION BY Error_category),'N2') AS '%_of_system_downtime',
	FORMAT(SUM(Downtime_in_hours) OVER (PARTITION BY Error_category),'N1') AS Total_Downtime_in_hours,
	FORMAT(Downtime_in_hours, 'N1') AS Downtime_in_hours,
	Error_source,
	Error,
	Start_Date_and_Time,
	End_Date_and_Time,
	System
FROM #ranked 
WHERE 
	Issue_rank = 1
ORDER BY 
	Start_Date
;
