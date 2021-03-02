-- Preppin Data
-- 2019 Week 21
-- https://preppindata.blogspot.com/2019/04/2019-week-21.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Append values with SELECT statement
-- Text parsing 
-- Use of CHARINDEX
-- Scaffolding

-- Tests
--SELECT * FROM pd2019w20_a_patient ;
--SELECT * FROM pd2019w21_additional_patients ;

--STEP 1
-- The date could not be imported as date, so the first step is to manually convert the "First_visit" field to date

DROP TABLE IF EXISTS #New_patients
SELECT
	Patient_Name,
	CONVERT(DATE,First_Visit,103) AS First_Visit,
	Length_of_Stay
INTO #New_patients
FROM
	pd2019w21_additional_patients
--SELECT * FROM #New_patients -- Test
;

--STEP 2 
--Union with old patients and get the discharge date

DROP TABLE IF EXISTS #All_patients_first_visit
	SELECT
		*,
		DATEADD(day,Length_of_Stay,First_Visit) AS discharge_date
	INTO
		#All_patients_first_visit
	FROM
		pd2019w20_a_patient
UNION ALL
	SELECT
		*,
		DATEADD(day,Length_of_Stay,First_Visit) AS discharge_date
	FROM
		#New_patients

--SELECT * FROM #All_patients_first_visit -- test
;

--STEP 3
--Get the new visits, which in reality, are check-ups

DROP TABLE IF EXISTS #Checkups
SELECT
	ap.[Name],
	ap.discharge_date,
	CONCAT( fc.Check_up,' check-up') AS Visit_type, -- Added for clarity
	fc.Months_After_Leaving,
	fc.Length_of_Stay,
	DATEADD(month, fc.Months_After_Leaving,ap.discharge_date) AS Check_up_date
INTO #Checkups
FROM
	#All_patients_first_visit ap
CROSS JOIN pd2019w20_b_Frequency_of_checkups fc

--SELECT * FROM #Checkups -- Test
;

-- STEP 4
-- Union the first visits with the checkups

DROP TABLE IF EXISTS #All_patients_all_visits
	SELECT
		Name,
		First_Visit,
		Length_of_Stay,
		'First Visit' AS Visit_type -- Added for clarity
	INTO #All_patients_all_visits
	FROM #All_patients_first_visit
UNION ALL
	SELECT
		Name,
		Check_up_date,
		Length_of_Stay,
		Visit_type
	FROM #Checkups
--SELECT * FROM #All_patients_all_visits -- Test
;

-- STEP 4
-- Perform the same process as with the original first visits (Based on week 20)

-- STEP 4a
--The scaffold need to be appended with one more row, to accomodate the 14th day of patient Andy

DROP TABLE IF EXISTS #New_Scaffold
	SELECT
		*
	INTO #New_Scaffold
	FROM
		pd2019w20_d_Scaffold pwds
UNION ALL
	SELECT 14 AS Value;

--SELECT * FROM #New_Scaffold -- Test
;

DROP TABLE IF EXISTS #Scaffolded
SELECT
	p.Name,
	p.First_Visit,
	p.Length_of_Stay AS Total_Length_of_Stay,
	p.Visit_type,
	DATEADD(DAY, s.value, p.First_Visit) AS Day_at_hospital,
	s.Value AS Day_number
INTO 
	#Scaffolded
FROM
	#All_patients_all_visits p-- Using all patients instead of the original table
CROSS JOIN 
	#New_Scaffold s -- Joined with the new scaffold with 14 lines
WHERE
	s.Value <= p.Length_of_Stay

SELECT * FROM #Scaffolded ORDER BY Name, Visit_type, Day_number -- Day_number -- Test
;

--STEP 5
--Get the limits for the cost of stays

DROP TABLE IF EXISTS #Cost_stays
SELECT 
	Length_of_Stay AS Length_of_Stay_Segment,
	CAST( Cost_per_Day AS DECIMAL (6,3) ) AS Cost_per_Day, -- For some reason, this was necessary to show the decimals at the end
--	CHARINDEX('-', Length_of_Stay) AS pos_of_dash, -- Test
--	LEN(Length_of_Stay) AS length_of_string, -- Test
	CAST( SUBSTRING(Length_of_Stay, 1, CHARINDEX('-', Length_of_Stay) - 1) AS INT) AS Stay_lower_limit,
	CAST( SUBSTRING(Length_of_Stay, CHARINDEX('-', Length_of_Stay) + 1, LEN(Length_of_Stay)-CHARINDEX('-', Length_of_Stay)) AS INT) AS Stay_upper_limit
INTO 
	#Cost_stays
FROM 
	pd2019w20_c_Cost_per_visit
	
--SELECT * FROM #Cost_stays -- Test
;

--STEP 6 
--Join the costs to the main table


DROP TABLE IF EXISTS #All_data
SELECT
	*,
	CASE WHEN Day_number BETWEEN c.Stay_lower_limit AND c.Stay_upper_limit THEN 1 ELSE 0 END AS test
INTO #All_data
FROM
	#Scaffolded s
INNER JOIN #Cost_stays c 
	ON s.Day_number BETWEEN c.Stay_lower_limit AND c.Stay_upper_limit
ORDER BY
	s.NAME,
	s.Day_number
--SELECT * FROM #All_data WHERE Name = 'Andy' ORDER BY Day_at_hospital; -- Test
;
	
-- STEP 7 - RESULTS
-- Result a
-- Daily hospital costs

SELECT 
	ROUND(AVG(Cost_per_day),2) AS Avg_Cost_per_day,
	Day_at_hospital,
	SUM(Cost_per_day) AS Cost_per_day,
	COUNT(Name) AS Number_of_Patients
FROM #All_data
GROUP BY 
	Day_at_hospital
;

-- Result b
-- Cost per patient

SELECT 
	SUM(Cost_per_day) AS Cost,
	Name,
	ROUND(AVG(Cost_per_day),2) AS Avg_Cost_per_day
FROM #All_data
GROUP BY 
	Name
ORDER BY 
	Name
	;

