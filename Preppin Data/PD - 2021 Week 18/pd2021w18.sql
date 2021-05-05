-- Preppin Data
-- 2021 Week 18
-- https://preppindata.blogspot.com/2021/05/2021-week-18-prep-air-project-overruns.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Date operations
-- 		to_char (to get weekday name)
-- Pivot with CASE and aggregations
-- WITH Clause

-- STEP 1 
-- Get completed date

WITH Table1 AS (
	SELECT
		project,
		sub_project,
		task,
		"Owner",
		scheduled_date,
		completed_in_days_from_scheduled_date AS Days_difference_to_schedule,
		(scheduled_date + completed_in_days_from_scheduled_date) AS Completed_date
	FROM public.pd2021w18_prep_air
)
-- STEP 2
-- Pivot the task column with the completed date values. Leave only project, subproject and owner to make it work

, Table2 AS (
	SELECT
		project,
		sub_project,
		"Owner",
		MAX(CASE WHEN task = 'Scope' THEN completed_date ELSE NULL END) AS task_scope,
		MAX(CASE WHEN task = 'Build' THEN completed_date ELSE NULL END) AS task_build,
		MAX(CASE WHEN task = 'Deliver' THEN completed_date ELSE NULL END) AS task_deliver
	FROM Table1
	GROUP BY
		project,
		sub_project,
		"Owner"
)
-- STEP 3
-- Join the the pivoted table back to the first one to get the date differences and the name of the weekday of the completed date

SELECT
	to_char(t1.completed_date, 'Day') AS completed_weekday,
	t1.task,
	(t2.task_build - t2.task_scope) AS scope_to_build_time,
	(t2.task_deliver - t2.task_build) AS build_to_delivery_time,
	t1.days_difference_to_schedule,
	t1.project,
	t1.sub_project,
	t1."Owner",
	t1.scheduled_date,
	t1.completed_date
FROM Table1 t1
	INNER JOIN Table2 t2
		ON t1.project = t2.project 
		AND t1.sub_project = t2.sub_project
		AND t1."Owner" = t2."Owner" 
;