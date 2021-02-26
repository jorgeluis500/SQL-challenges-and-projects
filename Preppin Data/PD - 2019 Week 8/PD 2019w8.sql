-- https://preppindata.blogspot.com/2019/04/2019-week-8.html

USE preppindata;

-- Exploration
SELECT * FROM preppindata.`2019w8_audit`;
SELECT * FROM preppindata.`2019w8_branch`;


-- Step 1. Split Store_ID and Branc Name from Branch_ID

WITH new_branch AS (
	SELECT 
		*,
		SUBSTRING_INDEX(Branch_ID,' - ',1) AS Store_ID,
		SUBSTRING_INDEX(Branch_ID,' - ',-1) AS Branch_name
	FROM 2019w8_branch
),

-- Step 2. 
-- a) Correct spellings in Type
-- b) Create the pivoted metrics for Stock Adjusted, Stock Volume and Theft
-- c) Sum quantity as Stock Variance
-- d) Group by Store_ID, Crime Ref and the corrected type

new_audit AS (
	SELECT 
		Store_ID,
		Crime_Ref_Number,
		COUNT(DISTINCT Crime_Ref_Number) AS Number_of_records,
		MAX(CASE WHEN Action = 'Stock Adjusted' THEN Date ELSE NULL END) AS Stock_Adjusted,
		SUM(Quantity) AS Stock_Variance,
		MAX(CASE WHEN Action = 'Theft' THEN Quantity ELSE NULL END) AS Stolen_Volume,
		MAX(CASE WHEN Action = 'Theft' THEN Date ELSE NULL END) AS Theft,
		CASE 
		WHEN Type = 'Soap Bar' THEN 'Bar'
		WHEN Type = 'Luquid' THEN 'Liquid'
		ELSE Type END AS Type
	FROM 2019w8_audit
	GROUP BY
		Store_ID,
		Crime_Ref_Number,
		CASE 
		WHEN Type = 'Soap Bar' THEN 'Bar'
		WHEN Type = 'Luquid' THEN 'Liquid'
		ELSE Type END
)

-- Final query
-- Join the new audit query (the previous one) with the new branch one
-- Calculate the days to complete adjustments column

SELECT 
	nb.Branch_name,
	na.Crime_Ref_Number, 
	DATEDIFF(na.Stock_Adjusted, na.Theft) AS Days_to_complete_adjustment,
    na.Number_of_records, 
	na.Stock_Adjusted, 
	na.Stock_Variance, 
	na.Stolen_Volume, 
	na.Theft, 
	na.Type
FROM new_audit na
LEFT JOIN new_branch nb
	ON na.Store_ID = nb.Store_ID
ORDER BY 
	na.Crime_Ref_Number
;
