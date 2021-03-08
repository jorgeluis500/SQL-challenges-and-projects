-- Preppin Data
-- 2019 Week 18
-- https://preppindata.blogspot.com/2019/04/2019-week-18.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Tokenization using STRING_SPLIT  function
-- Iterative loop with variables (at the end)

--USE PreppinData;

-- Expoloration and Tests

/*
SELECT 
	* 
FROM pd2019w18_anime pwa
-- WHERE name LIKE 'Gintam%' 	-- To compare with the result image
-- WHERE anime_id = 5348 		-- To test that all the data was imported correctly
-- WHERE genre IS NULL 			-- To test NULL genres
-- WHERE rating IS  NULL		-- To test NULL ratings
;

SELECT 
	genre,
	COUNT(*) AS records 
FROM pd2019w18_anime pwa
GROUP BY 
	genre
ORDER BY 
	COUNT(*) DESC
;
*/

-- SOLUTION
-- STEP 1
-- Include only TV Shows and movies
-- Ignore any anime without a rating or without any genres.
-- Ignore any anime with less than 10000 viewers (i.e. [Members])

DROP TABLE IF EXISTS #filtered_table
SELECT 
	*
--		, LEN(genre) - LEN(REPLACE(genre,',', '')) + 1 AS number_of_genres 	-- Counts the number of genres per line. Used in the scaffoilding approach. Not needed
--		, 1 AS link 														-- Used in the scaffoilding approach. Not needed
INTO #filtered_table
FROM pd2019w18_anime pwa
WHERE 
	p_type IN ('TV', 'Movie') 	-- Include only TV Shows and movies
	AND rating IS NOT NULL 		-- Ignore any anime without a rating or without any genres.
	AND genre IS NOT NULL 		-- Ignore any anime without a rating or without any genres.
	AND members > 10000 		-- Ignore any anime with less than 10000 viewers (i.e. [Members])

--SELECT * FROM #filtered_table; -- Test
;

--STEP 2
-- Using the STRING_SPLIT function:
-- The value column that is generated with this method has to be trimmed in order to produce accurate results when the Window Functions are used

DROP TABLE IF EXISTS #unpivoted
SELECT 
	anime_id,
	name,
	TRIM(value) as new_genre,
	p_type,
	episodes,
	rating,
	members AS viewers,
--	AVG(rating) OVER (PARTITION BY TRIM(value), p_type)  AS AVG_rating, -- Just for testing purposes
	MAX(rating) OVER (PARTITION BY TRIM(value), p_type)  AS MAX_rating
--	,AVG(members) OVER (PARTITION BY TRIM(value), p_type) AS Avg_viewers -- Just for testing purposes
INTO #unpivoted
FROM #filtered_table
	CROSS APPLY STRING_SPLIT(genre,',')

-- Tests	
--SELECT * FROM #unpivoted 
--WHERE new_genre = 'Cars'
--ORDER BY new_genre, p_type, rating
;

--STEP 3
-- Create the groupings

SELECT
	new_genre AS Genre,
	p_type AS 'Type',
	CAST( AVG(rating) AS DECIMAL (3,2)) AS Avg_rating,
	CAST( MAX(rating) AS DECIMAL (3,2)) AS Max_rating,
	AVG(viewers) AS Avg_viewers,
	MAX(CASE WHEN rating = MAX_rating THEN name ELSE NULL END) AS Prime_Example
FROM #unpivoted
GROUP BY
	new_genre,
	p_type
ORDER BY
	new_genre,
	p_type DESC
;

-- ANOTHER APPROACH
--STEP 2 

/*
-- This is not necessary and it has a dead end since SQL server does not support Regular Expressions. Way better to use the STRING_SPLIT function
-- However, it has educational value

--SELECT MAX(number_of_genres) AS max_number_of_genres FROM #filtered_table; -- Test to see what the maximum number of genres is

-- Create a Scaffolding table to join to the original table

DROP TABLE IF EXISTS #Scaffolding
CREATE TABLE #Scaffolding (Counter INT, link INT)
--SELECT * FROM #Scaffolding; -- Test

-- Declare the variable with the maximum value for the counter
DECLARE @max_genres INT = 0
SET @max_genres = (SELECT MAX(number_of_genres) FROM #filtered_table)

-- Declare the counter
DECLARE @counter INT = 1

-- Execute the loop
WHILE (@counter <= @max_genres)
BEGIN
	INSERT INTO #Scaffolding VALUES
	(@counter, 1)
	SET @counter = @counter + 1
END
--SELECT * FROM #Scaffolding; -- Test
;

-- STEP 3
-- Join the filtered table to the scaffolding table to generate the lines for each anime_id

SELECT
	anime_id,
	name,
	genre,
	p_type,
	episodes,
	rating,
	members,
	number_of_genres,
	Counter
FROM #filtered_table ft
INNER JOIN #Scaffolding s 
	ON ft.link = s.link
	AND s.Counter <= ft.number_of_genres 	-- Only bring lines with less or equal the number of genres
;
*/
