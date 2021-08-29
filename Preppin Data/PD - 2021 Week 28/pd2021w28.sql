-- Preppin Data
-- 2021 Week 28
-- https://preppindata.blogspot.com/2021/07/2021-week-28-its-coming-rome.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Parse date from string with to_date function
-- Aggregations and pivoting
-- Window functions for ranks
-- CTEs

-- STEP 1
-- Union both datasets

drop table if exists t_all_data;
create temporary table t_all_data as 
select 
	*,
	'Euro' as tournament
from pd2021w28_euros_csv
union all
select 
	*,
	'World Cup' as tournament
from pd2021w28_worldcup_csv
;
--select * from t_all_data; -- Test

-- STEP 2
-- Parse the fields
-- Clean any fields, correctly format the date the penalty was taken, & group the two German countries (eg, West Germany & Germany)

drop table if exists t_parsed;
create temporary table t_parsed as
select 
	*,
	to_date((game_date || '-' || event_year), 'DD-Mon-YYY') as new_date,
	case when winner = '�West Germany' then '�Germany' else winner end as new_winner,
	case when loser = '�West Germany' then '�Germany' else loser end as new_loser,
	case when losing_team_taker like '%scored%' then 1 else 0 end as losing_scored,
	case when losing_team_taker like '%missed%' then 1 else 0 end as losing_missed,
	case when winning_team_taker like '%scored%' then 1 else 0 end as winning_scored,
	case when winning_team_taker like '%missed%' then 1 else 0 end as winning_missed
from t_all_data
;
--select * from t_parsed; -- Test

-- STEP 3
-- First result dataset: Penalty position

with penalties as (
	select
		penalty_number,
		losing_scored + winning_scored as total_scored,
		losing_missed + winning_missed as total_missed,
		losing_scored + winning_scored + losing_missed + winning_missed as total_penalties
	from t_parsed
)
,penalties_grouped as (
	select
		penalty_number,
		sum(total_scored) * 100 / sum(total_penalties) as penalties_scored_pct, 
		sum(total_scored) as penalties_scored,
		sum(total_missed) as penalties_missed,
		sum(total_penalties) total_penalties
	from
		penalties
	group by 1
)
select
	rank() over (order by penalties_scored_pct desc) AS p_rank,
	penalties_scored_pct,
	penalties_scored,
	penalties_missed,
	total_penalties,
	penalty_number
from penalties_grouped
;

-- STEP 4
-- Combine winner and losers in one table

drop table if exists t_wl;
create temporary table t_wl as 
-- Winners
select
	game_number,
	penalty_number,
	winning_team_gk as gk,
	winning_team_taker as taker,
	round,
	tournament,
	new_date,
	new_winner as team,
	winning_scored as scored,
	winning_missed as missed,
	'winner' as team_result
from t_parsed
union all
-- Losers
select
	game_number,
	penalty_number,
	losing_team_gk as gk,
	losing_team_taker as taker,
	round,
	tournament,
	new_date,
	new_loser as team,
	losing_scored as scored,
	losing_missed as missed,
	'loser' as team_result
from t_parsed
;
--select * from t_wl; -- Test

-- STEP 4a
-- Second result dataset: Calculate the winning % per team

with teams_grouped as (
	select
		team,
		team_result,
		count(distinct new_date) as games 
	from t_wl
	group by 1,2
)
, teams_winnings as (
	select
		team,
	  	sum(case when team_result = 'winner' then games else 0 end) as shootouts_won,
		sum(games) as total_shootouts,
	  	round(sum(case when team_result = 'winner' then games else 0 end) * 100.0 / sum(games),0) as shootout_win_pct
	from teams_grouped
	group by 1
	order by 4 desc
)
select
	dense_rank() over (order by shootout_win_pct desc) as win_rank_pct,
	shootout_win_pct,
	total_shootouts,
	shootouts_won,
	team
from teams_winnings
where 
	shootouts_won <> 0
order by 
	shootout_win_pct desc,	
	total_shootouts
;

--STEP 4b
-- Third result dataset
--Scores %

with all_scores as (
	select
		team,
		sum(scored) as penalties_scored,
		sum(missed) as penalties_missed,
		round(sum(scored) *100.0 / (sum(scored) + sum(missed)),0) as penalties_score_pct -- the round here produces the expected result
	from t_wl
	group by 1
)
select
	dense_rank() over (order by penalties_score_pct desc) as penalties_score__pct_rank, 
	penalties_score_pct,
	penalties_missed,
	penalties_scored,
	team
from all_scores 
;

