-- Preppin Data
-- 2019 Week 30
-- https://preppindata.blogspot.com/2019/04/2019-week-30.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regular Expresions
-- Date and time construction
-- Scaffolding with a recursive query
-- Sentence tokenization
-- Unpivot with UNION

-- Remove puntuation with Regex (May 2021)
-- THIS CHANGE IN STEP 6 ALTERS THE FINAL RESULT BECAUSE THERE ARE MORE CLEAN WORDS. NOT GOING TO CHECK IT

-- STEP 1
-- Only keep tweets that give water / air temperatues
-- Extract Water and Air Temperatures as separate columns
-- Get the comment
-- Get date parts

USE Preppindata;

DROP TABLE IF EXISTS Extractions;
CREATE TEMPORARY TABLE Extractions
SELECT 
	Text,
	REGEXP_LIKE(Text, '\\d{2}\\s\\w{3}\\s\\d{4}:\\sWater\\s-\\s\\d{1,3}.\\dF\\s/\\s-?\\d{1,3}.?\\d?C;\\sAir\\s-\\s\\d{0,3}.?\\d?F\\s/\\s-?\\d{0,3}.?\\d?C\\..+') AS Is_temp_tweet,
	REGEXP_SUBSTR(Text, 'Water\\s-\\s\\d{1,3}.\\dF\\s/\\s-?\\d{1,3}.?\\d?C') AS Temp_water,
	REGEXP_SUBSTR(Text, 'Air\\s-\\s\\d{0,3}.?\\d?F\\s/\\s-?\\d{0,3}.?\\d?C') AS Temp_air,
	REGEXP_REPLACE(Text, '\\d{2}\\s\\w{3}\\s\\d{4}:\\sWater\\s-\\s\\d{1,3}.\\dF\\s/\\s-?\\d{1,3}.?\\d?C;\\sAir\\s-\\s\\d{0,3}.?\\d?F\\s/\\s-?\\d{0,3}.?\\d?C\\.', '') AS Comment,
	CONVERT(Tweet_Id, NCHAR(200)) AS Tweet_Id, -- Converts tweet id to text
	Created_At,
	RIGHT(REGEXP_SUBSTR(Created_At, '\\w{3}\\s\\d{2}'),2) AS dy,
	LEFT(REGEXP_SUBSTR(Created_At, '\\w{3}\\s\\d{2}'),3) AS mth,
	RIGHT(REGEXP_SUBSTR(Text, '\\d{2}\\s\\w{3}\\s\\d{4}'),4) AS yr,
	REGEXP_SUBSTR(Created_At, '\\s\\d{2}:\\d{2}:\\d{2}') AS times
FROM 2019w30_tweets_2 
;
-- SELECT * FROM Extractions; -- Test

-- STEP 2
-- Keep only temperature tweets
-- Get water and air temperatures separately
-- Get number of words in the comment
-- Get true date

DROP TABLE IF EXISTS Extractions_2;
CREATE TEMPORARY TABLE Extractions_2
SELECT
	`Text`,
	Is_temp_tweet,
	REGEXP_SUBSTR(Temp_water, 'Water') AS Cat_water,
	REPLACE(REGEXP_SUBSTR(Temp_water, '\\d{1,3}.\\dF'), 'F', '') AS Temp_water_F,
	REPLACE(REGEXP_SUBSTR(Temp_water, '\\d{1,3}.?\\d?C'), 'C', '') AS Temp_water_C,
	REGEXP_SUBSTR(Temp_air, 'Air') AS Cat_air,
	REPLACE(REGEXP_SUBSTR(Temp_air, '\\d{0,3}.?\\d?F'), 'F', '') AS Temp_air_F,
	REPLACE(REGEXP_SUBSTR(Temp_air, '\\d{0,3}.?\\d?C'), 'C', '')  AS Temp_air_C,
	Comment,
	LENGTH(Comment) - LENGTH(REPLACE(Comment, ' ', '')) AS number_of_words,
	Tweet_Id,
	Created_At,
	dy,
	mth,
	yr,
	times,
	STR_TO_DATE(CONCAT(yr, mth, dy, times), '%Y%M%d%H:%i:%s') AS True_created_at,
	1 AS link
FROM
	Extractions
WHERE
	Is_temp_tweet = 1
;
-- SELECT * FROM Extractions_2; -- Test


-- STEP 3
-- Create the scaffolding

-- 3a. Test to see what the maximum number of words is
-- SELECT MAX(number_of_words) AS max_words FROM Extractions_2; 

-- 3b. Create the scaffolding table using a recursive query

DROP TABLE IF EXISTS Scaffolding;
CREATE TEMPORARY TABLE Scaffolding
WITH RECURSIVE scf (n) 
AS (
	SELECT 
	1
	UNION ALL
	SELECT 
	n+1
	FROM scf
	WHERE n < (SELECT MAX(number_of_words) AS max_words FROM Extractions_2)
)
SELECT * FROM scf
;

-- STEP 4
-- Cross join with the scaffolding to get multiple lines per tweet.

DROP TABLE IF EXISTS Exploded;
CREATE TEMPORARY TABLE Exploded
SELECT 
	*, 
	regexp_substr(Comment,CONCAT('(\\s?\\S+\\s?){',n,'}')) AS Comment_gradual FROM Extractions_2 -- this gives me the {nth} group of (space word_any_character space)
CROSS JOIN Scaffolding s
WHERE number_of_words >= n -- Limit the number of rows to the number of words in each sentence
;
-- SELECT * FROM Exploded; -- Test

-- STEP 5
-- Extract the nth words

DROP TABLE IF EXISTS Words_extracted;
CREATE TEMPORARY TABLE Words_extracted
SELECT
	`Text`,
	Cat_water,
	Temp_water_F,
	Temp_water_C,
	Cat_air,
	Temp_air_F,
	Temp_air_C,
	Comment,
	n,
	number_of_words,
	CASE 
		WHEN number_of_words <> n THEN SUBSTRING_INDEX(Comment_gradual, ' ',-2) -- to get the last word in the gradual comment
		WHEN number_of_words = n THEN SUBSTRING_INDEX(Comment_gradual, ' ',-1) -- to get the last word in the whole sentence
		ELSE 'Check'
	END AS word_extracted,
	Tweet_Id,
	True_created_at AS Created_at
FROM
	Exploded 
;
-- SELECT * FROM Words_extracted; -- Test

-- STEP 6
-- Remove punctuation 

DROP TABLE IF EXISTS np; -- No punctuation
CREATE TEMPORARY TABLE np
SELECT 
	*, 
	regexp_replace(word_extracted, '[^\\w\\s\']','' ) AS clean_words -- best method
FROM Words_extracted
;
SELECT * FROM np; -- Test
-- THIS CHANGE ALTERS THE FINAL RESULT BECAUSE THERE ARE MORE CLEAN WORDS. NOT GOING TO CHECK IT

-- STEP 7
-- Join with the stopwords to leave the most relevants only
-- MySQL does not allow a temporary table to be used more than once. 
-- Therefore, I will create two identical tables to union them later in the unpivot operation

DROP TABLE IF EXISTS Pre_final_1;
CREATE TEMPORARY TABLE Pre_final_1
SELECT
	np.`Text`,
	np.Cat_water,
	np.Temp_water_F,
	np.Temp_water_C,
	np.Cat_air,
	np.Temp_air_F,
	np.Temp_air_C,
	np.Comment,
	np.clean_words,
-- 	np.n,
-- 	np.number_of_words,
-- 	np.word_extracted,
	np.Tweet_Id,
	np.Created_at
-- 	s.stopwords
FROM np
LEFT JOIN 0_stopwords_csv s
	ON np.clean_words = s.stopwords
WHERE s.stopwords IS NULL
;
-- SELECT * FROM Pre_final_1; -- Test


DROP TABLE IF EXISTS Pre_final_2;
CREATE TEMPORARY TABLE Pre_final_2
SELECT
	np.`Text`,
	np.Cat_water,
	np.Temp_water_F,
	np.Temp_water_C,
	np.Cat_air,
	np.Temp_air_F,
	np.Temp_air_C,
	np.Comment,
	np.clean_words,
	np.Tweet_Id,
	np.Created_at
FROM np
LEFT JOIN 0_stopwords_csv s
	ON np.clean_words = s.stopwords
WHERE s.stopwords IS NULL
;
-- SELECT * FROM Pre_final_2; -- Test


-- STEP 8
-- Unpivot. UNION the identical tables but with the different categories to get the final result

	SELECT
		clean_words AS Comment_Split,
		Cat_water AS Category,
		Temp_water_F AS TempF,
		Temp_water_C AS TempC,
		Comment,
		Tweet_Id,
		Created_at
	FROM
		Pre_final_1
UNION ALL
	SELECT
		clean_words AS Comment_Split,
		Cat_air AS Category,
		Temp_air_F AS TempF,
		Temp_air_C AS TempC,
		Comment,
		Tweet_Id,
		Created_at
	FROM
		Pre_final_2
;