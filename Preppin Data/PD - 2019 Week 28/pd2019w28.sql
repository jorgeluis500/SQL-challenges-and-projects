-- Preppin Data
-- 2019 Week 28
-- https://preppindata.blogspot.com/2019/04/2019-week-28.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
--Date and time assembly from separate fields
--Window functions to get cumulative sums and Previous row values

--SOLUTION

-- STEP 1
-- Assemble the date and time
-- Get the cumulative minutes for each employee
-- Get the columns using CASE statements (not the most elegant way)

WITH Preproc_1 AS 
	(
	SELECT 
		Employee,
		CAST ('2019-08-16' AS DATETIME) + CAST(Observation_Start_Time AS Datetime) AS Observation_Start_DateTime, -- Assemble date and time
		Observation_Interval,
		Observation_Length_mins,
		SUM(Observation_Length_mins) 
		OVER (	PARTITION BY 	Observation_Start_Time 
				ORDER BY 		Observation_Interval
				ROWS BETWEEN 	UNBOUNDED PRECEDING 
								AND
								CURRENT ROW
				) AS Cumulative_mins, 					-- Get the cumulative minutes
		CASE 
			WHEN Interaction_With = 'X'  THEN 'Manager'
			WHEN column6 = 'X' THEN 'Coworker'
			WHEN column7 = 'X' THEN 'Customer'
			WHEN column8 = 'X' THEN 'No One'
			ELSE 'Check' END AS Interaction,
		CASE 
			WHEN Task_Engagement = 'X'  THEN 'On Task'
			WHEN column10 = 'X' THEN 'Off Task'
			ELSE 'Check' END AS Task_Engagement,
		CASE 
			WHEN Manager_Proximity = 'X' THEN 'Next to (<2m)' 
			WHEN column12 = 'X' THEN 'Close to (<5m)'
			WHEN column13 = 'X' THEN 'Further(>5m)'
			WHEN column12 = 'X' THEN 'N/A'
			ELSE 'Check' END AS Manager_Proximity
	FROM pd2019w28 pw
	WHERE 
		Employee IS NOT NULL
	)

	
-- STEP 2
--Get the cumulative minutes from the previous row

, Preproc_2 AS 
	(
	SELECT 
		*,
		LAG(Cumulative_mins, 1,0) OVER (PARTITION BY Employee ORDER BY Employee, Observation_Start_Datetime, Observation_Interval) AS Lagged_mins 
	FROM Preproc_1
	)

-- STEP 3
-- Add the lagged minutes to form new observation start time

SELECT 
	Task_Engagement,
	Manager_Proximity,
	Interaction,
	Employee,
	DATEADD(MINUTE, Lagged_mins, Observation_Start_DateTime ) AS Observation_Start_time, 
	Observation_Length_mins,
	Observation_Interval
FROM Preproc_2 
;	

