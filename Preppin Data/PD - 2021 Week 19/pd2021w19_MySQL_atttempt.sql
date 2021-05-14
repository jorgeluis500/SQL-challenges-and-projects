-- Preppin Data
-- 2021 Week 19
-- https://preppindata.blogspot.com/2021/05/2021-week-19-prep-air-project-details.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regex
-- Regex extractions using groups

-- STEP 1
-- Parse the string into the different pieces

WITH parsed AS (
	SELECT
		CONCAT('Week ', Week) AS week_no,
		Commentary,
-- 		regexp_like(Commentary, '\\[\\w{3}/\\w{2,3}-\\w{2}\\]\\s.+\\sdays.+') AS regex_match_test,
		regexp_replace(Commentary, '\\[(\\w{3})/(\\w{2,3})-(\\w{2})\\]\\s(.+)', '$1') AS project_code,
		regexp_replace(Commentary, '\\[(\\w{3})/(\\w{2,3})-(\\w{2})\\]\\s(.+)', '$2') AS sub_project_code,
		regexp_replace(Commentary, '\\[(\\w{3})/(\\w{2,3})-(\\w{2})\\]\\s(.+)', '$3') AS task_code,
		regexp_replace(Commentary, '\\[(\\w{3})/(\\w{2,3})-(\\w{2})\\]\\s(.+)', '$4') AS detail
	FROM
		preppindata.pd2021w19_1_project_schedule_update
)

-- STEP 2
-- Join the other tables to bring the detailed names

SELECT * FROM parsed;

SELECT
	p.week_no,
	pl.project,
	sp.sub_project,
	t.task,
	p.detail
FROM parsed AS p
INNER JOIN preppindata.pd2021w19_project_lookup_table AS pl
	ON p.project_code = pl.project_code
INNER JOIN preppindata.pd2021w19_sub_project_lookup_table AS sp
	ON p.sub_project_code = sp.sub_project_code
INNER JOIN preppindata.pd2021w19_task_lookup_table AS t
	ON p.task_code = t.task_code
;
