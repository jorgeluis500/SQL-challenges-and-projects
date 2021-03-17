-- Preppin Data
-- 2019 Week 23
-- https://preppindata.blogspot.com/2019/04/2019-week-23.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Insert data from csv files
-- CHARINDEX
-- PATINDEX
-- Text parsing


-- STEP 1
-- Create the temporaty tables

-- File 1
DROP TABLE IF EXISTS #July_15
CREATE TABLE #July_15 (Day_name VARCHAR(80), Notes VARCHAR(255)); 

BULK INSERT #July_15 
FROM 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2019 week 23\Input\pd2019week23_a.csv'
WITH ( FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);

-- File 2
DROP TABLE IF EXISTS #July_22
CREATE TABLE #July_22 (Day_name VARCHAR(80), Notes VARCHAR(255))

BULK INSERT #July_22 
FROM 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2019 week 23\Input\pd2019week23_b.csv'
WITH ( FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);

-- File 3
DROP TABLE IF EXISTS #July_29
CREATE TABLE #July_29 (Day_name VARCHAR(80), Notes VARCHAR(255))

BULK INSERT #July_29 
FROM 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2019 week 23\Input\pd2019week23_c.csv'
WITH ( FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);

-- STEP 2
-- Union all the tables

DROP TABLE IF EXISTS #All_data
	SELECT 
		'2019-07-15'AS [Date],
		Day_name,
		LOWER(Notes) AS Notes
	INTO #All_data
	FROM #July_15
UNION ALL
	SELECT 
		'2019-07-22'AS [Date],
		Day_name,
		LOWER(Notes) AS Notes
	FROM #July_15
UNION ALL
	SELECT 
		'2019-07-29'AS [Date],
		Day_name,
		LOWER(Notes) AS Notes
	FROM #July_15
;

-- STEP 3 
-- Text parsing and number to add to the week start date

DROP TABLE IF EXISTS #Parsed_text
SELECT 
	*,
	CASE 
		WHEN Day_name = 'Monday' THEN 0 
		WHEN Day_name = 'Tuesday' THEN 1
		WHEN Day_name = 'Wednesday' THEN 2
		WHEN Day_name = 'Thursday' THEN 3
		WHEN Day_name = 'Friday' THEN 4
		WHEN Day_name = 'Saturday' THEN 5
		WHEN Day_name = 'Sunday' THEN 6
	ELSE NULL END AS add_to_date, 
	CHARINDEX(' ', Notes) AS First_space_position,
	PATINDEX('%wants%',Notes) Wants_position,
	CHARINDEX('£', Notes) AS Pound_position,
	PATINDEX('%of%',Notes) AS Of_position,
	SUBSTRING( Notes, 0, PATINDEX('%wants%',Notes)) as Name,
	SUBSTRING( Notes, CHARINDEX('£', Notes) + 1, PATINDEX('% of%', Notes) - CHARINDEX('£', Notes) ) AS Value,
	CASE 
		WHEN Notes LIKE '%jasmine%' THEN SUBSTRING( Notes, PATINDEX('%jasmine%',Notes), 7) 
		WHEN Notes LIKE '%lavender%' THEN SUBSTRING( Notes, PATINDEX('%lavender%',Notes), 8)
		WHEN Notes LIKE '%honey%' THEN SUBSTRING( Notes, PATINDEX('%honey%',Notes), 5)
	ELSE NULL END AS Scent,
	CASE 
		WHEN Notes LIKE '%jasmine%' THEN SUBSTRING( Notes, PATINDEX('%jasmine%',Notes) + 8, LEN(Notes) - PATINDEX('%jasmine%',Notes) )  
		WHEN Notes LIKE '%lavender%' THEN SUBSTRING( Notes, PATINDEX('%lavender%',Notes) + 9, LEN(Notes) - PATINDEX('%lavender%',Notes) )
		WHEN Notes LIKE '%honey%' THEN SUBSTRING( Notes, PATINDEX('%honey%',Notes) + 6, LEN(Notes) - PATINDEX('%honey%',Notes) )
	ELSE NULL END AS Product
INTO #Parsed_text
FROM #All_data

--SELECT * FROM #Parsed_text -- Test
;

-- STEP 4
-- Further parsing
DROP TABLE IF EXISTS #Parsed_2
SELECT
	CAST( DATEADD(day, add_to_date, [Date]) AS DATE ) AS new_date,
	Name,
	SUBSTRING(Name, 0, CHARINDEX(' ', Name)) AS Name_a,
	TRIM(SUBSTRING(Name, CHARINDEX(' ', Name), (LEN(Name) - CHARINDEX(' ', Name) +1) ) ) AS Name_b,
	Value,
	UPPER(LEFT(Scent,1)) +RIGHT(Scent,LEN(Scent)-1) AS Scent,
	Product,
	SUBSTRING(Product, 0, CHARINDEX(' ', Product)) AS Product_a,
	SUBSTRING(Product, CHARINDEX(' ', Product), (LEN(Product) - CHARINDEX(' ', Product) +1) ) AS Product_b,
	Notes
INTO #Parsed_2
FROM
	#Parsed_text
;

-- STEP 4
-- Capitalize and reassemble the strings

SELECT
	new_date AS [Date],
	UPPER(LEFT(Name_a,1)) + RIGHT(Name_a,LEN(Name_a) - 1 ) + ' ' + UPPER(LEFT(Name_b,1)) + RIGHT(Name_b, LEN(Name_b) - 1 ) AS Name,
	Value,
	Scent,
	UPPER(LEFT(Product_a,1)) + RIGHT(Product_a,LEN(Product_a) - 1 ) + ' ' + UPPER(LEFT(Product_b,1)) + RIGHT(Product_b, LEN(Product_b) - 1 ) AS Product,
	Notes
FROM
	#Parsed_2
;