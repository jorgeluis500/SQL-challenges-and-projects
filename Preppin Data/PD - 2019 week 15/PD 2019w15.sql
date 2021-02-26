-- PREPPIN DATA 2019 Week 15
-- https://preppindata.blogspot.com/2019/05/2019-week-15.html

USE PreppinData;

-- STEP 1
-- A Union of all the files

DROP TABLE IF EXISTS #union_all;
SELECT *, 'Central' AS Region INTO #union_all FROM dbo.pd2019w15_a_Central
UNION
SELECT *, 'East' AS Region FROM dbo.pd2019w15_b_East
UNION
SELECT *, 'North' AS Region FROM dbo.pd2019w15_c_North
UNION
SELECT *, 'South' AS Region FROM dbo.pd2019w15_d_South
UNION
SELECT *, 'West' AS Region FROM dbo.pd2019w15_e_West
;

-- STEP 2 
-- Add the calculations

DECLARE @@Stock NVARCHAR(200) = 'Aegon NV'; -- For test purposes

DROP TABLE IF EXISTS #stock_table_w_calcs;
SELECT *,
	SUM(Sales) OVER (PARTITION BY Stock) AS Total_sales,
	SUM(Sales) OVER (PARTITION BY Stock, Region) AS Total_Regional_Sales,
	Sales / SUM(Sales) OVER (PARTITION BY Stock) * 100.0 AS '%_of_Total_Sales',
	Sales / SUM(Sales) OVER (PARTITION BY Stock, Region) * 100.0 AS '%_of_Regional_Sales',
	COUNT(*) OVER (PARTITION BY Stock, Region ORDER BY Stock, Region) AS Transactions_per_region
INTO #stock_table_w_calcs
FROM #union_all
-- WHERE Stock = @@Stock -- For test purposes
-- ORDER BY Stock, Region
;

-- STEP 3
-- Leave only lines that show more than one transaction per state for the same stock

SELECT
    [%_of_Regional_Sales],
    [%_of_Total_Sales],
    Customer_ID,
    First_Name,
    Last_Name,
    Sales,
    Order_Date,
    Stock,
    Total_Regional_Sales,
    Total_sales
FROM
    #stock_table_w_calcs
WHERE
    Transactions_per_region > 1
;