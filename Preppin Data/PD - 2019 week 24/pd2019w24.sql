-- Preppin Data
-- 2019 Week 24
-- https://preppindata.blogspot.com/2019/04/2019-week-24.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regular Expresions

-- Tests
-- SELECT *,
-- 		REGEXP_SUBSTR(Field_1, '\\d+/\\d+/\\d+,\\s\\d+:\\d+:\\d+' ) AS date_time_raw,
-- 		LOCATE( ']', Field_1) As bracket_pos,
-- 		str_to_date( REGEXP_SUBSTR(Field_1, '\\d+/\\d+/\\d+'), '%d/%m/%Y' )  AS Date_extracted,
--      REGEXP_SUBSTR(Field_1, ',\\s\\d+:\\d+:\\d+') AS Time_extracted,
-- FROM 2019w24_messsages;

-- STEP 1a
-- Extract the releveant fields from the messages table, using Regex

DROP TABLE IF EXISTS Messages_fp; -- fp: first pass
CREATE TEMPORARY TABLE Messages_fp 
	SELECT 
		*,
		str_to_date( REGEXP_SUBSTR(Field_1, '\\d+/\\d+/\\d+,\\s\\d+:\\d+:\\d+'), '%d/%m/%Y, %H:%i:%s'  ) AS Datetime_extracted,
        REGEXP_SUBSTR(Field_1, '[[:ascii:]]+:', (LOCATE( ']', Field_1)+2) ) AS Person_extracted,
		substring_index(Field_1,':',-1) AS Message_extracted
	FROM 2019w24_messsages
;	
-- SELECT * FROM Messages_fp ; -- Test

-- STEP 1b
-- Clean person field and transform the file join it later

DROP TABLE IF EXISTS Messages_sp; -- sp: second pass
CREATE TEMPORARY TABLE Messages_sp
SELECT 
	Field_1,
	Datetime_extracted,
    REGEXP_SUBSTR(Person_extracted, '[[:alpha:]]+') AS Person, 
    Message_extracted,
    length(Message_extracted) - length(REPLACE(Message_extracted,' ','')) AS number_of_words,
	DAY(Datetime_extracted) AS day_extracted,
    MONTH(Datetime_extracted) AS month_extracted,
    HOUR(Datetime_extracted) AS hour_extracted,
    weekday(Datetime_extracted) AS day_of_the_week
FROM Messages_fp 
;
-- SELECT * FROM Messages_sp ; -- Test

-- STEP 2a
-- Extract fields from the dates file

DROP TABLE IF EXISTS Dates_fp; -- fp: first pass
CREATE TEMPORARY Table Dates_fp 
SELECT 
    *,
    REGEXP_SUBSTR(Date,'\\d+') AS day_number,
    REGEXP_SUBSTR(Date,'[[:alpha:]]+') AS month_name
FROM 2019w24_dates
;
-- SELECT * FROM Dates_fp; -- Test

-- STEP 2b
-- Add month numbers to the table to join it later. In a real-life version, we either use a dates table or create a complete CASE statement

DROP TABLE IF EXISTS Dates_sp; -- sp: second pass
CREATE TEMPORARY Table Dates_sp 
SELECT 
    day_number,
    CASE 
	WHEN month_name = 'May' THEN 5
	WHEN month_name = 'Jun' THEN 6
    WHEN month_name = 'Jul' THEN 7
    ELSE NULL END AS month_number,
    is_Holiday
FROM
    Dates_fp
;
-- SELECT * FROM Dates_sp; -- Test

-- STEP 3
-- Join both tables and create the aggregations

-- Test
-- SELECT * FROM Messages_sp  m
-- INNER JOIN Dates_sp d
-- 	ON m.day_extracted = d.day_number AND m.month_extracted = d.month_number
;

SELECT 
	m.Person AS `Name`,
    COUNT(*) AS `Text`,
    SUM(m.number_of_words) AS Number_of_Words,
    ROUND(AVG(m.number_of_words),1) AS Avg_words_per_sentence,
    SUM(CASE 
			WHEN d.is_Holiday = 'Weekday'
			AND (m.hour_extracted BETWEEN 9 AND 11 OR m.hour_extracted BETWEEN 13 AND 16)
        THEN 1 ELSE 0 END) AS Text_while_at_work,
	ROUND( SUM( CASE 
					WHEN d.is_Holiday = 'Weekday'
					AND (m.hour_extracted BETWEEN 9 AND 11 OR m.hour_extracted BETWEEN 13 AND 16)
				THEN 1 ELSE 0 END) / COUNT(*) *100.0 ,2 ) AS percentage_sent_from_work
FROM Messages_sp m
INNER JOIN Dates_sp d 
	ON m.day_extracted = d.day_number
	AND m.month_extracted = d.month_number
GROUP BY 
	m.Person