-- Preppin Data
-- 2021 Week 16
-- https://preppindata.blogspot.com/2021/03/2021-week-16.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivoting with independent tables and Union
-- Window functions
-- Join

-- STEP 1 
-- Enrich the main table by parsing the results and calculating the absolute goal difference

DROP TABLE IF EXISTS temp_enriched;
CREATE TEMPORARY TABLE temp_enriched AS 
SELECT *,
	CAST( LEFT(game_result, 1) AS INT) home_team_goals,
	CAST( RIGHT(game_result, 1) AS INT) AS away_team_goals,
	CASE WHEN 
	home_team IN ('Arsenal', 'Chelsea', 'Liverpool', 'Man City', 'Man Utd', 'Spurs') OR 
	away_team IN ('Arsenal', 'Chelsea', 'Liverpool', 'Man City', 'Man Utd', 'Spurs') 
	THEN 1 ELSE 0 END AS is_super_league
FROM
	pd2021w16_premier_league
;
--SELECT * FROM temp_enriched; -- Test

-- STEP 2
-- Separate Home teams and Away teams, remove NULLS and get their metrics

-- Home teams
DROP TABLE IF EXISTS temp_home_teams;
CREATE TEMPORARY TABLE temp_home_teams AS 
SELECT
	home_team,
	home_team_goals AS goals_scored,
	away_team_goals AS goals_conceded,
	CASE 
	WHEN home_team_goals > away_team_goals THEN 3 
	WHEN home_team_goals = away_team_goals THEN 1
	WHEN home_team_goals < away_team_goals THEN 0
	ELSE null END AS points,
	is_super_league
FROM temp_enriched
WHERE game_result IS NOT NULL
;
--SELECT * FROM temp_home_teams; -- Test

-- Away teams
DROP TABLE IF EXISTS temp_away_teams;
CREATE TEMPORARY TABLE temp_away_teams AS
SELECT
	away_team,
	away_team_goals AS goals_scored,
	home_team_goals AS goals_conceded,
	CASE 
	WHEN home_team_goals < away_team_goals THEN 3 
	WHEN home_team_goals = away_team_goals THEN 1
	WHEN home_team_goals > away_team_goals THEN 0
	ELSE null END AS points,
	is_super_league
FROM temp_enriched
WHERE game_result IS NOT NULL
;
--SELECT * FROM temp_away_teams; -- Test

-- STEP 3
--Union the team tables

DROP TABLE IF EXISTS temp_all_teams;
CREATE TEMPORARY TABLE temp_all_teams AS
	SELECT
		home_team AS team,
		goals_scored,
		goals_conceded,
		points,
		is_super_league
	FROM
		temp_home_teams
UNION ALL
	SELECT
		away_team,
		goals_scored,
		goals_conceded,
		points,
		is_super_league
	FROM
		temp_away_teams
;

-- STEP 4 - Current league
-- Aggregate the metrics, group by team and create the rank for the Current league

DROP TABLE IF EXISTS current_league_table;
CREATE TEMPORARY TABLE current_league_table AS
SELECT
	ROW_NUMBER() OVER 
		(ORDER BY 
		SUM(points) DESC, 
		(SUM(goals_scored) - SUM(goals_conceded)) DESC 
		) AS team_position,
	team,
	COUNT(*) AS total_games_played,
	SUM(points) AS total_points,
	SUM(goals_scored) - SUM(goals_conceded) AS goal_difference
FROM
	temp_all_teams
GROUP BY 
	team
ORDER BY SUM(points) DESC
;
SELECT * FROM current_league_table; 

-- STEP 5 - Updated league
-- Aggregate the metrics, group by team and create the rank for the Updated league, where the superleague teams should be filtered

DROP TABLE IF EXISTS updated_league_table;
CREATE TEMPORARY TABLE updated_league_table AS
SELECT
	ROW_NUMBER() OVER 
		(ORDER BY 
		SUM(points) DESC, 
		(SUM(goals_scored) - SUM(goals_conceded)) DESC 
		) AS team_position,
	team,
	COUNT(*) AS total_games_played,
	SUM(points) AS total_points,
	SUM(goals_scored) - SUM(goals_conceded) AS goal_difference
FROM
	temp_all_teams
WHERE is_super_league = 0 -- excludes the super league teams
GROUP BY 
	team
ORDER BY SUM(points) DESC
;
--SELECT * FROM current_league_table; -- Test

-- STEP 6
-- Compare the position change in the league when the superleague teams are excluded

SELECT
	cl.team_position - 	ul.team_position AS position_change, 
	ul.team_position,
	ul.team,
	ul.total_games_played,
	ul.total_points,
	ul.goal_difference
FROM
	updated_league_table ul
LEFT JOIN current_league_table cl
	ON ul.team= cl.team
ORDER BY 
	ul.team_position 
;