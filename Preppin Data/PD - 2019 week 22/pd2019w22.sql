--Preppin Data
--2019 Week 22
--https://preppindata.blogspot.com/2019/07/2019-week-22.html

-- There must be more elagant solutions, probably in MySQL and PostgreSQL where RANGE is fully supported

-- STEP 1. 
-- Calculate the moving average and use a rank to later leave only those over the first 7 days

WITH added_columns AS (
	SELECT 
		[﻿Date],
		Sales,
		CAST( AVG(Sales) OVER (ORDER BY [﻿Date]
				ROWS BETWEEN
				6 PRECEDING
				AND
				CURRENT ROW) AS Decimal (5,2) ) AS Moving_average_all,
		ROW_NUMBER() OVER (ORDER BY [﻿Date]) AS Ranked_days
	FROM pd2019w22_a
)

-- STEP 2
-- "Hide" the first 7 days

SELECT 
	[﻿Date],
	Sales,
	CASE WHEN Ranked_days < 7 THEN NULL ELSE Moving_average_all END AS Moving_average
FROM added_columns
ORDER BY [Date]
;

--LEARNING AND TECHNIQUES
-- Window functions
