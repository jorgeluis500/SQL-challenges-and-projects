-- Preppin Data
-- 2019 Week 16

-- STEP 1 
-- Union all the files in a temporary table

DROP TABLE IF EXISTS #all_union
SELECT *
INTO #all_union
FROM pd2019w16_a_bar_soap
UNION
SELECT *
FROM pd2019w16_b_BudgetSoap
UNION
SELECT *
FROM pd2019w16_c_LiquidSoap
UNION
SELECT *
FROM pd2019w16_d_PlasmaSoap
UNION
SELECT *
FROM pd2019w16_e_SoapAccessories
;
-- SELECT * FROM #all_union; -- Test

-- STEP 2
-- Filter the date, group by email and put into another temp table

DROP TABLE IF EXISTS #grouped_and_filtered
SELECT Email,
       SUM(Order_Total) AS Order_Total       
-- Order_Date
INTO #grouped_and_filtered
FROM #all_union
WHERE Order_Date >= DATEADD(month, -6, '2019-05-24')
GROUP BY Email
;
-- SELECT * FROM #grouped_and_filtered; -- Test

-- STEP 3 
-- Test and exploration of different Window functions

DROP TABLE IF EXISTS #data_with_functions
SELECT Email,
       Order_Total,
       COUNT(*) OVER () AS total_lines,
       COUNT(*) OVER () * 0.08 AS Limit_row_with_8_pct,
       ROW_NUMBER() OVER (ORDER BY Order_Total DESC) AS Last_6_month_rank,
       PERCENT_RANK() OVER (ORDER BY Order_Total DESC) AS percent_rank,
       CUME_DIST() OVER (ORDER BY Order_Total DESC) AS cumulative_dist
INTO #data_with_functions
FROM #grouped_and_filtered
;
-- SELECT * FROM #data_with_functions; -- Test

-- STEP 4
-- Filter by cumulative distribution less or equal than 8%

SELECT 
    Last_6_month_rank,
    Email, 
    CAST (Order_Total AS DECIMAL (5,2)) AS Order_Total,
    COUNT(*) OVER () AS Total_rows
FROM #data_with_functions
WHERE cumulative_dist <= 0.08