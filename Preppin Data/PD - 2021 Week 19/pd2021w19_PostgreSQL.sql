-- Preppin Data
-- 2021 Week 19
-- https://preppindata.blogspot.com/2021/05/2021-week-19-prep-air-project-details.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regular Expression, Regex
-- Unpivot with UNNEST and str_to_array
-- Joins
-- Capitalize strings

-- STEP 1
-- Get the codes and the message into the different pieces

WITH parsed AS (
	SELECT
		'Week '|| week AS week_no,
		substring(commentary, '\w{3}') AS project_code,
		REPLACE(substring(commentary, '/\w{2,3}'),'/','') AS sub_project_code,
		REPLACE(substring(commentary, '-\w{2}'),'-','') AS task_code,
		regexp_replace(commentary,'\[\w{3}/\w{2,3}-\w{2}\]', '|||', 'g') AS message
--		commentary
	FROM
		pd2021w19_1_project_schedule_update
)

-- STEP 2
-- Parse the detail

, parsed2 AS (

	SELECT
		week_no,
		project_code,
		lower(sub_project_code) AS sub_project_code,
		task_code,
		UNNEST(string_to_array(message, ' ||| ')) AS detail_1
	FROM
		parsed
)

-- STEP 3
-- Parse the days and the name
, parsed3 AS (
	SELECT
		week_no,
		project_code,
		sub_project_code,
		task_code,
		INITCAP(TRIM(REPLACE(substring(detail_1, '\s\w{3}\.'), '.', ''))) AS "name",
		REPLACE(substring(detail_1, '\d{1,2}\sdays'), ' days', '') AS days_noted,
		TRIM(REPLACE(detail_1, '|||', '')) AS detail
	FROM
		parsed2
)
-- STEP 4
-- Join the other tables to bring the detailed names

SELECT 
	p.week_no,
	pl.project,
	sp.sub_project,
	t.task,
	o."Name",
	p.days_noted,
	p.detail
FROM parsed3 AS p
INNER JOIN pd2021w19_project_lookup_table AS pl
	ON p.project_code = pl.project_code
INNER JOIN pd2021w19_sub_project_lookup_table AS sp
	ON p.sub_project_code = sp.sub_project_code
INNER JOIN pd2021w19_task_lookup_table AS t
	ON p.task_code = t.task_code
INNER JOIN pd2021w19_owner_lookup_table AS o
	ON p."name" = o.abbreviation
;

