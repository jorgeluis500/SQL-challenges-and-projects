-- Preppin Data
-- 2019 Week 23
-- https://preppindata.blogspot.com/2019/04/2019-week-23.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- STRING_SPLIT function 
-- Window Function

-- 2 missing lines in the result, compared to the official output file

-- STEP 0
-- Rank the concerts to identify the duplicates

DROP TABLE IF EXISTS #Step_0
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY Artist, Concert_Date, Concert, Venue, Location ORDER BY Artist, Concert_Date, Concert, Venue, Location ) AS rank_for_dup
INTO #Step_0
FROM 	pd2019w25_gigs_data g

--SELECT * FROM #Step_0 -- Test
;

-- STEP 1
-- Join the data, parse what can be parse and create an ID

DROP TABLE IF EXISTS #Step_1
SELECT
	ROW_NUMBER() OVER (ORDER BY ConcertID) AS New_ID,
	rank_for_dup,
	LEFT(ll.LongLats, CHARINDEX(',',ll.LongLats)-1) AS Longitude,
	SUBSTRING(ll.LongLats, CHARINDEX(',',ll.LongLats) + 2, LEN(ll.LongLats) - CHARINDEX(',',ll.LongLats) + 2) AS Latitude,
	g.ConcertID,
	g.Artist,
	g.Concert_Date,
	CASE WHEN g.Concert IS NULL THEN 'Null' ELSE g.Concert END AS Concert, -- Necessary to split the rows later
	LEN(g.Concert) - LEN(REPLACE(g.Concert,'/','')) AS number_of_slashes,
	g.Venue,
	g.Location,
	hl.Hometown,
	hl.Longitude AS Home_Latitude,
	hl.Latitude AS Home_Longitude
INTO #Step_1
FROM
	#Step_0 g
LEFT JOIN pd2019w25_gigs_data_LongLats ll 
	ON g.[Location] = ll.[Location]
INNER JOIN pd2019w25_home_locations hl 
	ON g.Artist = hl.Artist
WHERE rank_for_dup = 1 -- Remove the duplicates

-- SELECT * FROM #Step_1 -- Test
;

-- STEP 2
--Split the Concert field to get the 

SELECT 
--	New_ID, For testing purposes
	Longitude,
	Latitude,
	CASE WHEN (TRIM(value) = 'Ed Sheeran' OR  TRIM(value) = 'Ben Howard') THEN '' ELSE TRIM(value) END AS Fellow_Artist,
--	ConcertID,
--	Artist,
	Concert_Date,
	Concert,
	Venue,
	Location,
	Hometown,
	Home_Longitude,
	Home_Latitude
FROM #Step_1
CROSS APPLY STRING_SPLIT (Concert, '/')
ORDER BY New_ID
;