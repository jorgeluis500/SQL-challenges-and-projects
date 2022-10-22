-- Preppin Data
-- 2022 Week 39
--https://preppindata.blogspot.com/2022/09/2022-week-39-filling-in-for-hr.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Window functions

-- STEP 1
-- Create the partition for the employee (Record ID already gives the order)
-- Fill down the work level using windown function

DROP TABLE IF EXISTS 	t_partitions ;
CREATE TEMPORARY TABLE 	t_partitions AS
SELECT
	record_id,
	employee,
	MAX(CASE WHEN employee IS NOT NULL THEN record_id ELSE NULL END) OVER (ORDER BY record_id) AS employee_partition,
	work_level,
	MAX(CASE WHEN work_level IS NOT NULL THEN work_level ELSE NULL END) OVER (ORDER BY record_id) AS work_level_filled_down,
	stage,
	"Date"
FROM
	public.pd2022w39_fill_down
;
--SELECT * FROM t_partitions; -- Test

-- STEP 2
-- Fill down employee using a window function

WITH t_partitions_2 AS (
	SELECT
		record_id,
		employee,
		employee_partition,
		MAX(employee) OVER (PARTITION BY employee_partition) AS employee_filled_down,
		work_level,
		work_level_filled_down,
		stage,
		"Date"
	FROM
		t_partitions
)
-- STEP 3
-- Show only relevant columns
SELECT
	record_id,
	employee_filled_down AS employee,
	work_level_filled_down AS 	work_level,
	stage,
	"Date"
FROM
	t_partitions_2
;