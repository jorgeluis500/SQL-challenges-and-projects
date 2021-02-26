-- PREPPIN DATA 2019 Week 13
-- https://preppindata.blogspot.com/2019/05/2019-week-13.html

USE PreppinData;

--STEP 1
-- Exploration, joining data and getting the date in proper format. Put it in a temporary table

DROP TABLE IF EXISTS #full_data;
SELECT
    t.[Account],
    t.[Date],
    t.[Transaction],
    t.[Balance],
    cl.[Name],
    cl.[Max_Credit],
	Convert(date, t.[Date], 103) AS converted_date
INTO #full_data
FROM
    dbo.pd2019w13a_transactions t
    LEFT JOIN dbo.pd2019w13b_customers_lookup cl
            ON t.Account = cl.Account;

-- STEP 2
-- Create the needed fields to add time dimensions and comparisons in a second temporary table

DROP TABLE IF EXISTS #enriched_data;
SELECT 
	*,
	MONTH(converted_date) AS Month_number,
	DATEPART(week, converted_date) as week_number,
	DATEPART(quarter, converted_date) as quarter_number,
	CASE WHEN Balance <= 0 THEN 1 ELSE 0 END AS day_below_zero_balance,
	CASE WHEN Balance >= -Max_Credit THEN 0 ELSE 1 END AS day_beyond_credit_limit
INTO #enriched_data
FROM #full_data;

-- STEP 3
-- Create the reports using the relevant aggregations

-- Report 1. Weekly
SELECT 
	SUM(day_below_zero_balance) AS Days_Below_Zero_balance,
	SUM(day_beyond_credit_limit) AS Days_Beyond_Max_Credit,
	FORMAT(AVG([Transaction]*1.0), 'N0') AS Weekly_Avg_Transactions,
    FORMAT(AVG([Balance]*1.0),'N2') AS Weekly_Avg_Balances,
	week_number AS wk,
	Account,
	Name, 
	MIN(Date) AS 'Date'
FROM #enriched_data
GROUP BY
	week_number,
	Account,
	Name;

	-- Report 2. Monthly
SELECT 
	SUM(day_below_zero_balance) AS Days_Below_Zero_balance,
	SUM(day_beyond_credit_limit) AS Days_Beyond_Max_Credit,
	FORMAT(AVG([Transaction]*1.0), 'N0') AS Monthly_Avg_Transactions,
    FORMAT(AVG([Balance]*1.0),'N2') AS Monthly_Avg_Balances,
	Month_number AS 'Month',
	Account,
	Name, 
	MIN(Date) AS 'Date'
FROM #enriched_data
GROUP BY
	Month_number,
	Account,
	Name;

-- Report 3. Quarterly
SELECT 
	SUM(day_below_zero_balance) AS Days_Below_Zero_balance,
	SUM(day_beyond_credit_limit) AS Days_Beyond_Max_Credit,
	FORMAT(AVG([Transaction]*1.0), 'N0') AS Quarterly_Avg_Transactions,
    FORMAT(AVG([Balance]*1.0),'N2') AS Quarterly_Avg_Balances,
	quarter_number AS 'Quarter',
	Account,
	Name, 
	MIN(Date) AS 'Date'
FROM #enriched_data
GROUP BY
	quarter_number,
	Account,
	Name;
