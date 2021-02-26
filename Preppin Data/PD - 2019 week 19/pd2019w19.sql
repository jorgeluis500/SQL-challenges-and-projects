-- PREPPIN DATA 
-- 2019 Week 19
-- https://preppindata.blogspot.com/2019/06/2019-week-19.html

-- Data from tour de france. The team must have
-- Have seven or more riders complete the tour
-- Must average 100 minutes or less behind the leader as a team (less than 6000 seconds)
-- Make all time fields seconds before doing any of the calculations

-- SQL Server used

--SELECT * FROM pd2019w19_TdFrance_times; -- Exploration

--STEP 1. Parse the times

DROP TABLE IF EXISTS #Parsed_times
SELECT	*,
		LEFT(Times,2) AS Time_hours,
		SUBSTRING(Times, CHARINDEX(' ',Times) + 1, 2 ) AS Time_minutes, -- CHARINDEX gives the position of a character in a string
		SUBSTRING(Times, CHARINDEX(CHAR(39),Times) + 2, 2 ) AS Time_seconds, -- CHAR(39) is the apostrophe
		SUBSTRING(Gap, CHARINDEX(' ',Gap) + 1, 2 ) AS Gap_hours,
		SUBSTRING(Gap, CHARINDEX('h',Gap) + 2, 2 ) AS Gap_minutes,
		SUBSTRING(Gap, CHARINDEX(CHAR(39),Gap) + 2, 2 ) AS Gap_seconds
INTO 	#Parsed_times
FROM 	pd2019w19_TdFrance_times
--SELECT * FROM #Parsed_times -- Test
;
	
-- STEP 2. Convert the times to seconds and add them up

DROP TABLE IF EXISTS #Total_seconds
SELECT 	[Rank],
		Rider,
		Rider_No,
		Team,
		Times,
		Gap,
		(Time_hours * 3600) + (Time_minutes * 60) + Time_seconds AS Time_total_seconds,
		(Gap_hours * 3600) + (Gap_minutes * 60) + Gap_seconds AS Gap_total_seconds
INTO	#Total_seconds
FROM	#Parsed_times
--SELECT * FROM #Total_seconds -- Test
	;

--STEP 3. Create the aggregations

DROP TABLE IF EXISTS #Aggregated
SELECT	Team,
		COUNT(Rider_No) AS Number_of_Riders,
		AVG(Gap_total_seconds) AS Avg_gap
INTO 	#Aggregated
FROM	#Total_seconds
GROUP BY Team
--SELECT * FROM #Aggregated -- Test
;	

-- STEP 4. Filter by the condtions

SELECT	(Avg_gap / 60) AS Team_Avg_gap_in_min,
		Team,
		Number_of_Riders
FROM	#Aggregated
WHERE	Number_of_Riders >= 7 	AND Avg_gap <= 6000
