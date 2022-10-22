-- Preppin Data
-- 2022 Week 40
-- https://preppindata.blogspot.com/2022/10/2022-week-40-times-tables.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Recursive queries
-- Pivoting using SUM CASE

-- STEP 1
-- Generate all the numbers using a recursive query with the min and max given by the numbers in the table
-- The max number of values is given by the max number in the table multiplied by itself

DROP TABLE IF EXISTS 	t_recursive ;
CREATE TEMPORARY TABLE 	t_recursive AS
WITH RECURSIVE cte_numbers(n_min, n_max)
AS (
    SELECT 
        (SELECT MIN(numbers) FROM public.pd2022w40_numbers) AS n_min,
        (SELECT MAX(numbers) FROM public.pd2022w40_numbers) AS n_max
    UNION ALL
    SELECT    
        n_min + 1,
        n_max
    FROM    
        cte_numbers
    WHERE n_min < n_max * n_max -- The total number of results
    )
SELECT 
    *
FROM 
    cte_numbers;
--SELECT * FROM t_recursive; -- Test
   
-- STEP 2
-- Generate all the values that will be in the rows and the columns

DROP TABLE IF EXISTS 	t_rows_columns ;
CREATE TEMPORARY TABLE 	t_rows_columns AS
SELECT
 	*,
 	CASE WHEN MOD((n_min * 1.0), n_max) = 0 THEN n_max ELSE  MOD((n_min * 1.0), n_max) END AS  n_rows,
 	CEILING((n_min * 1.0) / n_max) AS n_columns
FROM t_recursive
;
--SELECT * FROM t_rows_columns; -- Test

-- STEP 3 Pivot the data using SUM CASE

SELECT
	n_rows AS "number",
	SUM(CASE WHEN n_columns = 1 THEN n_rows *n_columns ELSE 0 END) AS "1",
	SUM(CASE WHEN n_columns = 2 THEN n_rows *n_columns ELSE 0 END) AS "2",
	SUM(CASE WHEN n_columns = 3 THEN n_rows *n_columns ELSE 0 END) AS "3",
	SUM(CASE WHEN n_columns = 4 THEN n_rows *n_columns ELSE 0 END) AS "4",
	SUM(CASE WHEN n_columns = 5 THEN n_rows *n_columns ELSE 0 END) AS "5",
	SUM(CASE WHEN n_columns = 6 THEN n_rows *n_columns ELSE 0 END) AS "6",
	SUM(CASE WHEN n_columns = 7 THEN n_rows *n_columns ELSE 0 END) AS "7",
	SUM(CASE WHEN n_columns = 8 THEN n_rows *n_columns ELSE 0 END) AS "8",
	SUM(CASE WHEN n_columns = 9 THEN n_rows *n_columns ELSE 0 END) AS "9"
FROM t_rows_columns
GROUP BY 
	n_rows
ORDER BY 
	n_rows