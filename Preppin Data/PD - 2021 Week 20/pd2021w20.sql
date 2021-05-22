-- Preppin Data
-- 2021 Week 20
-- https://preppindata.blogspot.com/2021/05/2021-week-20-controlling-complaints.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Standard deviation functions
-- Window functions
-- Temp tables

-- STEP 1 
-- Calculate Mean and Standard Deviation (To match the official result, the std dev of the sample must be used)

DROP TEMPORARY TABLE IF EXISTS t_mean_std;
CREATE TEMPORARY TABLE t_mean_std
SELECT
	c_date,
	week,
	complaints,
	department,
	AVG(complaints) OVER (PARTITION BY week) AS mean,
	stddev_samp(complaints) OVER (PARTITION BY week) AS std_dev
	
FROM
	pd2021w20_prep_air_complaints
;

-- SELECT * FROM t_mean_std; -- Test
-- STEP 2

-- Calculate control limits

DROP TEMPORARY TABLE IF EXISTS t_cl; -- Control Limits
CREATE TEMPORARY TABLE t_cl
SELECT
	c_date,
	week,
	complaints,
	department,
	mean,
	std_dev,
	mean + (1 * std_dev) AS upper_control_limit_1sd,
	mean - (1 * std_dev) AS lower_control_limit_1sd,
	mean + (2 * std_dev) AS upper_control_limit_2sd,
	mean - (2 * std_dev) AS lower_control_limit_2sd,
	mean + (3 * std_dev) AS upper_control_limit_3sd,
	mean - (3 * std_dev) AS lower_control_limit_3sd	
FROM
	t_mean_std
;
-- SELECT * FROM t_cl; -- Test

-- STEP 3
-- Calculate if the point is an outlier for each case (1,2,3 std dev) and the variation for each case

-- A. For 1 std dev:
SELECT
	c_date,
	week,
	complaints,
	department,
	mean,
	std_dev,
	upper_control_limit_1sd,
	lower_control_limit_1sd,
	upper_control_limit_1sd - lower_control_limit_1sd AS variation_1sd,
	CASE
		WHEN complaints > upper_control_limit_1sd
		OR complaints < lower_control_limit_1sd THEN 'Outside'
		ELSE NULL
	END AS is_outlier_1sd
FROM
	t_cl
WHERE
	complaints > upper_control_limit_1sd
	OR complaints < lower_control_limit_1sd
;

-- B. For 2 std dev:
SELECT
	c_date,
	week,
	complaints,
	department,
	mean,
	std_dev,
	upper_control_limit_2sd,
	lower_control_limit_2sd,
	upper_control_limit_2sd - lower_control_limit_2sd AS variation_2sd,
	CASE
		WHEN complaints > upper_control_limit_2sd
		OR complaints < lower_control_limit_2sd THEN 'Outside'
		ELSE NULL
	END AS is_outlier_2sd
FROM
	t_cl
WHERE
	complaints > upper_control_limit_2sd
	OR complaints < lower_control_limit_2sd

;

-- B. For 3 std dev:
SELECT
	c_date,
	week,
	complaints,
	department,
	mean,
	std_dev,
	upper_control_limit_3sd,
	lower_control_limit_3sd,
	upper_control_limit_3sd - lower_control_limit_3sd AS variation_3sd,
	CASE
		WHEN complaints > upper_control_limit_3sd
		OR complaints < lower_control_limit_3sd THEN 'Outside'
		ELSE NULL
	END AS is_outlier_3sd
FROM
	t_cl
WHERE
	complaints > upper_control_limit_3sd
	OR complaints < lower_control_limit_3sd

;