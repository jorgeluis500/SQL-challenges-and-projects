USE preppindata;


-- Step 1. Split the category in the Company data table to get Bar and Liquid (eliminate Soap)

-- DROP TEMPORARY TABLE New_mars_19; 
CREATE TEMPORARY TABLE New_mars_19
SELECT 
	'Mar 19' AS Month,
    Country,
	substring_index(Category, ' ',1) AS Clean_Category,
	City, 
	Units_Sold
FROM 2019w6b_en_mar19
;
-- Test
SELECT * FROM New_company_data;

-- Step 2. Trim Type of soap in `2019w6c_soap_price` to get Bar instead of Bar with space

-- DROP TEMPORARY TABLE New_soap_price; 
CREATE TEMPORARY TABLE New_soap_price
SELECT 
	TRIM(Type_of_Soap) as Clean_Type_of_Soap,
	Manufacturing_Cost_per_Unit,
	Selling_Price_per_Unit
FROM 2019w6c_soap_price
;
-- Test
SELECT * FROM New_soap_price;

-- Step 3. Join new company data with new soap and get the profit

SELECT 
	nm.Month,
    nm.Country, 
	nm.City, 
	nm.Units_Sold, 
	CONCAT(nm.Clean_Category, ' ', 'Soap') AS Category, -- to revert it to the original name
    nsp.Manufacturing_Cost_per_Unit,
    nsp.Selling_Price_per_Unit,
    ROUND((nsp.Selling_Price_per_Unit - nsp.Manufacturing_Cost_per_Unit) * nm.Units_Sold,0) AS Profit
FROM New_mars_19 nm
LEFT JOIN New_soap_price nsp
	ON nm.Clean_Category = nsp.Clean_Type_of_Soap
;

-- Step 4. Create the aggeregations out the previous query

SELECT 
	nm.Month,
    nm.Country, 
	-- nm.City, 
	-- nm.Units_Sold, 
	CONCAT(nm.Clean_Category, ' ', 'Soap') AS Category,
	-- nsp.Manufacturing_Cost_per_Unit,
    -- nsp.Selling_Price_per_Unit,
    SUM(ROUND((nsp.Selling_Price_per_Unit - nsp.Manufacturing_Cost_per_Unit) * nm.Units_Sold,0)) AS Profit
FROM New_mars_19 nm
LEFT JOIN New_soap_price nsp
	ON nm.Clean_Category = nsp.Clean_Type_of_Soap
GROUP BY
	nm.Month,
    nm.Country, 
	nm.Clean_Category
;

-- Step 5 Union the previous query with the company data

	SELECT 
	*
	FROM 2019w6a_company_data
UNION
	SELECT 
		nm.Month,
		nm.Country, 
		-- nm.City, 
		-- nm.Units_Sold, 
CONCAT(nm.Clean_Category, ' ', 'Soap') AS Category,
		-- nsp.Manufacturing_Cost_per_Unit,
		-- nsp.Selling_Price_per_Unit,
		SUM(ROUND((nsp.Selling_Price_per_Unit - nsp.Manufacturing_Cost_per_Unit) * nm.Units_Sold,0)) AS Profit
	FROM New_mars_19 nm
	LEFT JOIN New_soap_price nsp
		ON nm.Clean_Category = nsp.Clean_Type_of_Soap
	GROUP BY
		nm.Month,
		nm.Country, 
		nm.Clean_Category
;
