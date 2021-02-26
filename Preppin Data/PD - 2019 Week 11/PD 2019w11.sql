-- https://preppindata.blogspot.com/2019/04/2019-week-11.html

SELECT * FROM 2019w11_json_stock_data;

-- Steps
-- Tests
	-- Check for valid rows
    -- Get row number
    -- Convert Epoch time into standard date
	-- Generate individual columns
-- Step 1. Get dates separately
-- Step 2. Get value columns and pivot them
-- Step 3. Join the two queries

-- Tests

SELECT 
	*,
	JSON_Name LIKE '%.timestamp.%' OR 
	JSON_Name LIKE '%.open.%' OR 
	JSON_Name LIKE '%.volume.%' OR 
	JSON_Name LIKE '%.high.%' OR 
	JSON_Name LIKE '%.low.%' OR 
	JSON_Name LIKE  '%.adjclose.%' OR 
	JSON_Name LIKE  '%.close.%' OR 
	JSON_Name LIKE  '%.open.%' AS valid_column,
    SUBSTRING_INDEX(JSON_Name,'.',-1) AS Row_n,

	CASE WHEN JSON_Name LIKE '%.timestamp.%' THEN FROM_UNIXTIME(JSON_ValueString) ELSE 0 END AS Date,
	CASE WHEN JSON_Name LIKE '%.volume.%' THEN JSON_ValueString  ELSE 0 END AS volume,
	CASE WHEN JSON_Name LIKE '%.high.%' THEN JSON_ValueString  ELSE 0 END AS high,
	CASE WHEN JSON_Name LIKE '%.low.%' THEN JSON_ValueString  ELSE 0 END AS low,
	CASE WHEN JSON_Name LIKE '%.adjclose.%' THEN JSON_ValueString  ELSE 0 END AS adjclose,
	CASE WHEN JSON_Name LIKE '%.close.%' THEN JSON_ValueString  ELSE 0 END AS close,
	CASE WHEN JSON_Name LIKE '%.open.%' THEN JSON_ValueString  ELSE 0 END AS open

FROM 2019w11_json_stock_data;

-- Step 1. Get dates separately

WITH Dates AS (
	SELECT 
		SUBSTRING_INDEX(JSON_Name,'.',-1) AS Row_n,
		CASE WHEN JSON_Name LIKE '%.timestamp.%' THEN FROM_UNIXTIME(JSON_ValueString) ELSE 0 END AS Date
	FROM 2019w11_json_stock_data
	WHERE 
		JSON_Name LIKE '%.timestamp.%'
),

-- Step 2. Get value columns and pivot them

Stock_values AS (
SELECT 
	SUBSTRING_INDEX(JSON_Name,'.',-1) AS Row_n,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.volume.%' THEN JSON_ValueString  ELSE 0 END),2) AS volume,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.high.%' THEN JSON_ValueString  ELSE 0 END),2) AS high,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.low.%' THEN JSON_ValueString  ELSE 0 END),2) AS low,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.adjclose.%' THEN JSON_ValueString  ELSE 0 END),2) AS adjclose,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.close.%' THEN JSON_ValueString  ELSE 0 END),2) AS close,
	ROUND(MAX(CASE WHEN JSON_Name LIKE '%.open.%' THEN JSON_ValueString  ELSE 0 END),2) AS open
FROM 2019w11_json_stock_data
WHERE 
	JSON_Name LIKE '%.open.%' OR 
	JSON_Name LIKE '%.volume.%' OR 
	JSON_Name LIKE '%.high.%' OR 
	JSON_Name LIKE '%.low.%' OR 
	JSON_Name LIKE  '%.adjclose.%' OR 
	JSON_Name LIKE  '%.close.%' OR 
	JSON_Name LIKE  '%.open.%'
GROUP BY
	SUBSTRING_INDEX(JSON_Name,'.',-1)
)

-- Step 3. Join the two queries

SELECT 
	d.Date, 
	sv.volume, 
	sv.high, 
	sv.low, 
	sv.adjclose, 
	sv.close, 
	sv.open, 
	sv.Row_n 
FROM Dates d
LEFT JOIN Stock_values sv
	ON d.Row_n = sv.Row_n
;