-- Preppin Data
-- 2021 Week 13
-- https://preppindata.blogspot.com/2021/03/2021-week-13.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- UNION
-- Window functions (Rank)
-- Temp tables and WITH clause


-- STEP 1
-- Input all the files

DROP TABLE IF EXISTS All_files;
CREATE TEMPORARY TABLE All_files

SELECT * FROM pd2021w13_a_15_16
UNION ALL 
SELECT * FROM pd2021w13_b_16_17
UNION ALL 
SELECT * FROM pd2021w13_c_17_18
UNION ALL
SELECT * FROM pd2021w13_d_18_19
UNION ALL 
SELECT * FROM pd2021w13_e_19_20
;

-- STEP 2
-- Remove all goalkeepers from the data set
-- Remove all records where appearances = 0
-- Create a new “Open Play Goals” field (the goals scored from open play is the number of goals scored that weren’t penalties or freekicks)


DROP TABLE IF EXISTS New_metrics;
CREATE TEMPORARY TABLE New_metrics
SELECT
	*,
	Goals - 
		(CASE WHEN `Penalties scored` IS NULL THEN 0 ELSE `Penalties scored` END) - 
		(CASE WHEN `Freekicks scored` IS NULL THEN 0 ELSE `Freekicks scored` END)  
	AS Open_play_goals
FROM
	All_files
WHERE
	`Position` <> 'Goalkeeper' -- Remove all goalkeepers from the data set
	AND Appearances <> 0 -- Remove all records where appearances = 0
ORDER BY Name
;

-- STEP 3
-- Calculate the totals for each of the key metrics across the whole time period for each player, (be careful not to lose their position)
-- Create an open play goals per appearance field across the whole time period

DROP TABLE IF EXISTS Aggregations;
CREATE TEMPORARY TABLE Aggregations
SELECT
	SUM(Open_play_goals) AS Open_play_goals,
	SUM(`Goals with right foot`) AS Goals_with_right_foot,
	SUM(`Goals with left foot`) AS Goals_with_left_foot,
	`Position`,
	SUM(Appearances) AS Appearances,
	SUM(Goals) AS Total_goals,
	SUM(Open_play_goals) / SUM(Appearances) As Open_play_goals_per_game,
	SUM(`Headed goals`) AS Headed_goals,
	Name
FROM
	New_metrics 
GROUP BY
	Name,
	`Position`
;

-- STEP 4
-- Create Ranks

-- 4a. Rank the players for the amount of open play goals scored across the whole time period, 
-- we are only interested in the top 20 (including those that are tied for position) – Output 1

SELECT
	Open_play_goals,
	Goals_with_right_foot,
	Goals_with_left_foot,
	`Position`,
	Appearances,
	RANK() OVER ( ORDER BY Open_play_goals DESC ) AS Overall_rank,
	Total_goals,
	Open_play_goals_per_game,
	Headed_goals,
	Name
FROM
	Aggregations
ORDER BY
	Open_play_goals DESC
LIMIT 20
;

-- 4b. Rank the players for the amount of open play goals scored across the whole time period by position, 
-- we are only interested in the top 20 (including those that are tied for position) – Output 2

WITH Ranked_p AS (
	SELECT
		RANK() OVER (PARTITION BY `Position` ORDER BY Open_play_goals DESC ) AS Rank_by_position,
		Open_play_goals,
		Goals_with_right_foot,
		Goals_with_left_foot,
		`Position`,
		Appearances,
		Total_goals,
		Open_play_goals_per_game,
		Headed_goals,
		Name
	FROM
		Aggregations
	ORDER BY
		`Position`,
		Open_play_goals DESC
)

SELECT * FROM ranked_p WHERE Rank_by_position < = 20
;

