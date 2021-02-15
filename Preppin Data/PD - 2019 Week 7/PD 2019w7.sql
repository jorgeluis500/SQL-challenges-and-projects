USE preppindata;

-- Exploration

SELECT * FROM 2019w7_dep;
SELECT * FROM 2019w7_allo;

-- Step 1 Aggregate the cargo and volume by Departure_ID in the Allocation table

WITH Allo_agg AS (
SELECT 
	Departure_ID, 
	SUM(Weight_Allocated) AS Weight_Allocated, 
	SUM(Volume_Allocated) AS Volume_Allocated
FROM 2019w7_allo
GROUP BY Departure_ID
ORDER BY Departure_ID
),

-- Step 2 Create a departure_ID from a clean date in the Departures table

Dep_with_ID AS(
SELECT 
	*,
	CONCAT(Ship_ID, '-',
	LPAD(DAY(Clean_Departure_Date),2,0), '-',
	LPAD(MONTH(Clean_Departure_Date),2,0), '-',
	YEAR(Clean_Departure_Date)
	) AS Departure_ID
FROM (
	SELECT 
	*,
	str_to_date(Departure_Date, "%c/%e/%Y") AS Clean_Departure_Date
	FROM 2019w7_dep
	) as cdd
)

-- Final query
-- Join the tables and create the tests for Weight and Volume

SELECT
	did.Ship_ID, 
	did.Departure_Date, 
	did.Max_Weight, 
	did.Max_Volume,
	ag.Weight_Allocated,
	ag.Volume_Allocated,
    CASE WHEN ag.Weight_Allocated > did.Max_Weight THEN 'TRUE' ELSE 'FALSE' END AS Max_Weight_Exceeded,
    CASE WHEN ag.Volume_Allocated > did.Max_Volume THEN 'TRUE' ELSE 'FALSE' END AS Max_Volume_Exceeded
FROM Allo_agg ag
LEFT JOIN Dep_with_ID did
	ON ag.Departure_ID = did.Departure_ID
ORDER BY
did.Departure_Date
    ;