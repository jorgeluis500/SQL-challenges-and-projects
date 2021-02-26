-- Preppind Data
-- 2019 Week 20
-- https://preppindata.blogspot.com/2019/06/2019-week-20.html

--Use the scaffold provided to build out a complete data set that includes all days one of our customers is in the hospital
--To determine cost, you pay �100 for each of the first three days, then �80 for the next four days and then �75 for each of the following days.
--Aggregate the data to form a view of total cost and average cost.


--USE PreppinData;

--SELECT * FROM pd2019w20_a_patient pwap; -- Exploration

--STEP 1. Use the scaffold provided to build out a complete data set that includes all days one of our customers is in the hospital

DROP TABLE IF EXISTS #Scaffolded
SELECT
	p.Name,
	p.First_Visit,
	p.Length_of_Stay AS Total_Length_of_Stay,
	DATEADD(DAY, s.value, p.First_Visit) AS Day_at_hospital,
	s.Value AS Day_number
INTO 
	#Scaffolded
FROM
	dbo.pd2019w20_a_patient p
CROSS JOIN 
	pd2019w20_d_Scaffold s
WHERE
	s.Value <= p.Length_of_Stay

--SELECT * FROM #Scaffolded -- Test
;

--STEP 2.Get the limits for the cost of stays

DROP TABLE IF EXISTS #Cost_stays
SELECT 
	Length_of_Stay AS Length_of_Stay_Segment,
	CAST( Cost_per_Day AS DECIMAL (6,3) ) AS Cost_per_Day, -- For some reason, this was necessary to show the decimals at the end
--	CHARINDEX('-', Length_of_Stay) AS pos_of_dash, -- Test
--	LEN(Length_of_Stay) AS length_of_string, -- Test
	SUBSTRING(Length_of_Stay, 1, CHARINDEX('-', Length_of_Stay)-1) AS Stay_lower_limit,
	SUBSTRING(Length_of_Stay, CHARINDEX('-', Length_of_Stay)+1, LEN(Length_of_Stay)-CHARINDEX('-', Length_of_Stay)) AS Stay_upper_limit
INTO 
	#Cost_stays
FROM 
	pd2019w20_c_Cost_per_visit
	
--SELECT * FROM #Cost_stays -- Test
;

--STEP 3 Join the cost to the main table

DROP TABLE IF EXISTS #All_data
SELECT
	*
INTO #All_data
FROM
	#Scaffolded s
INNER JOIN #Cost_stays c 
	ON s.Day_number BETWEEN c.Stay_lower_limit AND c.Stay_upper_limit
ORDER BY
	s.NAME,
	s.Day_number
--SELECT * FROM #All_data; -- Test
;

-- RESULT A
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

-- RESULT B
-- Cost per patient

SELECT 
	SUM(Cost_per_day) AS Cost,
	Name,
	ROUND(AVG(Cost_per_day),2) AS Avg_Cost_per_day
FROM #All_data
GROUP BY 
	Name
;
