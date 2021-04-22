-- Preppin Data
-- 2021 Week 16
-- https://preppindata.blogspot.com/2021/03/2021-week-16.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.

DROP TABLE IF EXISTS temp_premier_league;
CREATE TEMPORARY TABLE temp_premier_league (
round_no INT,
game_date timestamp,
game_location VARCHAR(75),
home_team VARCHAR(50),
away_team VARCHAR(50),
game_result VARCHAR(25)
)
;


COPY temp_premier_league FROM 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2021 Week 16\Input\PL Fixtures.csv' DELIMITER ',' HEADER CSV
;

SELECT * FROM temp_premier_league;