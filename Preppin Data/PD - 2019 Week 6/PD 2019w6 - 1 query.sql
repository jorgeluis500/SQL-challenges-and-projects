-- Preppin Data
-- 2019 Week 6 - File 2 with more eficient query
-- https://preppindata.blogspot.com/2019/03/2019-week-6.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.


USE preppindata;

-- Step 1. Split the category in the Company data table to get Bar and Liquid (eliminate Soap)

WITH New_mars_19 AS (
SELECT 
	'Mar 19' AS Month,
    Country,
	substring_index(Category,' ',1) AS Clean_Category,
	City, 
	Units_Sold
FROM 2019w6b_en_mar19
),

-- Step 2. Trim Type of soap in `2019w6c_soap_price` to get Bar instead of Bar with space
 
New_soap_price AS (
SELECT 
	TRIM(Type_of_Soap) as Clean_Type_of_Soap,
	Manufacturing_Cost_per_Unit,
	Selling_Price_per_Unit
FROM 2019w6c_soap_price
)

-- Final query. 
-- Join new company data with new soap and get the profit
-- Reverse the Clean Category to category with 'Soap'
-- SUM the profit to group by Month, Country and Category
-- Union the previous query with the company data
 
	SELECT 
	*
	FROM 2019w6a_company_data
UNION
	SELECT 
		nm.Month,
		nm.Country, 
		CONCAT(nm.Clean_Category, ' ', 'Soap') AS Category,
		SUM(ROUND((nsp.Selling_Price_per_Unit - nsp.Manufacturing_Cost_per_Unit) * nm.Units_Sold,0)) AS Profit
	FROM New_mars_19 nm
	LEFT JOIN New_soap_price nsp
		ON nm.Clean_Category = nsp.Clean_Type_of_Soap
	GROUP BY
		nm.Month,
		nm.Country, 
		nm.Clean_Category
;

