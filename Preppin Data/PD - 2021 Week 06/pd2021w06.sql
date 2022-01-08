-- Preppin Data
-- 2021 Week 6
-- https://preppindata.blogspot.com/2021/02/2021-week-6-comparing-prize-money-for.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- String manipulation
-- Aggregations
-- Pivot with CASE and aggregations
-- Ranks with Window functions

-- STEP 1
-- Change money data type, 
-- Rankings and ranking difference

DROP TABLE IF EXISTS 	t_new_table ;
CREATE TEMPORARY TABLE 	t_new_table AS
WITH step_1 AS ( 
	SELECT
		"PLAYER NAME" AS player_name,
		CAST(REPLACE(REPLACE("MONEY", '$', ''), ',','') AS INT ) AS new_money,
		events,
		tour
	FROM
		public.pd2021w06_officialmoney_csv
)
SELECT
	*,
	RANK() OVER (ORDER BY new_money DESC) AS overall_rank,
	RANK() OVER (PARTITION BY tour ORDER BY new_money DESC) AS tour_rank,
	RANK() OVER (ORDER BY new_money DESC) - RANK() OVER (PARTITION BY tour ORDER BY new_money DESC) AS rank_diff
FROM step_1
;

--SELECT * FROM t_new_table; -- Test

-- Aggregations

DROP TABLE IF EXISTS 	t_aggregations ;
CREATE TEMPORARY TABLE 	t_aggregations AS
SELECT
	tour,
	count(DISTINCT player_name) AS number_of_players,
	sum(events) AS number_of_events,
	round(avg(new_money/events),0) AS average_money_per_event,-- According to the official solution: https://preppindata.blogspot.com/2021/02/2021-week-6-solution.html
	sum(new_money) AS total_prize_money,
	avg(rank_diff) AS avg_diff_in_rank
FROM
	t_new_table
GROUP BY 1
;

-- STEP 3 
-- Unpivot with UNNEST and ARRAY

DROP TABLE IF EXISTS 	t_unpivoted ;
CREATE TEMPORARY TABLE 	t_unpivoted AS
SELECT tour,
	UNNEST( ARRAY['avg_diff_in_rank','number_of_players','number_of_events','average_money_per_event','total_prize_money']) AS measure,
	UNNEST(ARRAY[avg_diff_in_rank, number_of_players, number_of_events, average_money_per_event, total_prize_money]) AS thing
FROM t_aggregations
;
-- STEP 4
-- Pivot again and calculate differences betweeen tours

WITH pivoted AS (
	SELECT
		measure,
		MAX(CASE WHEN tour = 'PGA' THEN thing ELSE NULL END) AS PGA,
		MAX(CASE WHEN tour = 'LPGA' THEN thing ELSE NULL END) AS LPGA
	FROM t_unpivoted 
	GROUP BY measure
)
SELECT
	*,
	lpga - pga AS difference_between_tours
FROM pivoted
;