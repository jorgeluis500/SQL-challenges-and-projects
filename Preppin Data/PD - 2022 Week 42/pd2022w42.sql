-- Preppin Data
-- 2022 Week 42
-- https://preppindata.blogspot.com/2022/10/2022-week-42-missing-training-data.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Scaffolding with recursive query
-- CROSS JOIN 
-- Extract day of week from a date
-- Fill down with sequence logic made of window functions in CTEs

--Step 1 
-- Create the min and max dates for the scaffolding

DROP TABLE IF EXISTS 	t_dates ;
CREATE TEMPORARY TABLE 	t_dates AS
SELECT
	MIN("Date") AS min_date,
	MAX("Date") AS max_date
FROM
	public.pd2022w42_player_training
;
SELECT * FROM t_dates; -- Test

--STEP 2
--Create the scaffolding with a recursive query

DROP TABLE IF EXISTS t_scf;
CREATE TEMPORARY TABLE t_scf AS
WITH RECURSIVE scf (n, date_scf) AS 
(
	SELECT
	1,
	(SELECT min_date FROM t_dates)
	UNION ALL
	SELECT 
	n + 1,
	date_scf + 1
	FROM scf
	WHERE date_scf < (SELECT max_date FROM t_dates)
)
SELECT * FROM scf
;

--SELECT * FROM t_scf; -- Test

-- STEP 3 
-- Test to make sure all the players have had the three sessions ever

SELECT
	player,
	COUNT( DISTINCT "Session") AS sessions_per_player
FROM public.pd2022w42_player_training
GROUP BY 1
ORDER BY 1
;
-- Yes, they do

--|player   |sessions_per_player|
--|---------|-------------------|
--|Player 1 |3                  |
--|Player 10|3                  |
--|Player 11|3                  |
--|Player 12|3                  |
--|Player 13|3                  |
--|Player 14|3                  |
--|Player 15|3                  |
--|Player 2 |3                  |
--|Player 3 |3                  |
--|Player 4 |3                  |
--|Player 5 |3                  |
--|Player 6 |3                  |
--|Player 7 |3                  |
--|Player 8 |3                  |
--|Player 9 |3                  |

-- STEP 4
-- Join the unique players and sessions with the scaffold

DROP TABLE IF EXISTS 	t_cross_joined ;
CREATE TEMPORARY TABLE 	t_cross_joined AS
WITH t_attributes AS (
	SELECT
		DISTINCT player, "Session"
	FROM public.pd2022w42_player_training
)
SELECT
	* 
FROM t_attributes
CROSS JOIN  t_scf
;
--SELECT * FROM t_cross_joined; -- Test

-- STEP 5 
-- Join the newly created cross_joined dataset with the original one

DROP TABLE IF EXISTS 	t_all_data ;
CREATE TEMPORARY TABLE 	t_all_data AS
SELECT
	cj.player,
	cj."Session",
	cj.date_scf,
	o.score
FROM
	t_cross_joined AS cj
LEFT JOIN public.pd2022w42_player_training AS o
	ON  cj.player = o.player
	AND cj."Session" = o."Session"
	AND cj.date_scf = o."Date"
;
-- SELECT * FROM t_all_data; -- Test

-- STEP 6
-- Fill down logic

-- Step 6a
-- Flag the carried overs and exclude the weekends
-- Create a numeric condition that will be used to group the "blocks" of data that include the null dates

DROP TABLE IF EXISTS 	t_fill_down ;
CREATE TEMPORARY TABLE 	t_fill_down AS
WITH t_flag_block AS (
	SELECT
		*,
		CASE WHEN score IS NULL THEN 'Carried Over' ELSE 'Actual' END AS flag,
		CASE WHEN score IS NOT NULL THEN 1 ELSE 0 END AS block
		FROM t_all_data
	WHERE date_part('dow', date_scf) NOT IN (0,6) -- EXCLUDE the weekends
)
-- Step 6b: Create a running sum of the blocks. This will group the last known value and then the nulls
, t_rsum AS (
	SELECT
		*,
		SUM(block) OVER (PARTITION BY player, "Session" ORDER BY date_scf) AS running_sum_block
	FROM t_flag_block
)
-- Step 6c. Get the first value of each running sum block. This is the fill down
SELECT
	*,
	FIRST_VALUE(score) OVER (PARTITION BY player, "Session", running_sum_block ) AS score_adj
FROM t_rsum
;
--SELECT * FROM t_fill_down; -- Test

--STEP 7
-- Present results

SELECT
	player,
	"Session",
	date_scf AS session_date,
	score_adj AS score,
	flag
FROM
	t_fill_down
;