-- Preppin Data
-- 2019 Week 9
-- https://preppindata.blogspot.com/2019/04/2019-week-9.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Tokenization with STRING_SPLIT

-- STEP 1 
-- Remove the handle

DROP TABLE IF EXISTS #nh -- No handle
SELECT 
	*,
	REPLACE(Tweet,'@C&BSudsCo', '') AS No_handle
INTO #nh
FROM PreppinData.dbo.[2019w9_complaints_csv]

--SELECT * FROM #nh -- Test
;

--STEP 2
--Remove punctuation (not the most elegant way)

DROP TABLE IF EXISTS #np -- No punctuation
SELECT 
	No_handle,
	REPLACE(
		REPLACE(
			REPLACE( 
				REPLACE(No_handle, '?', '')
			, '!' , '' )
		, '.' , ' ' )
	, ',' , '' )
	AS No_punctuation
INTO #np
FROM #nh

--SELECT * FROM #np -- Test
;

--STEP 3
-- Unpivot the words

DROP TABLE IF EXISTS #Unpivoted
SELECT 
	No_handle,
	TRIM(value) AS Words
INTO #Unpivoted
FROM #np
CROSS APPLY STRING_SPLIT (No_punctuation, ' ')

--SELECT * FROM #Unpivoted -- Test
;

-- STEP 4 
-- Join with the stopwords to leave the most relevants only

SELECT 
			Words,
			No_handle AS Tweet
FROM 		#Unpivoted u
LEFT JOIN 	PreppinData.dbo.[2019w9_stopwords_csv] s
		ON 	u.Words = s.Word
WHERE 		s.Word IS NULL AND u.Words <> ''
;


