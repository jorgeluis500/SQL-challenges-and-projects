-- Preppin Data
-- 2019 Week 30
-- https://preppindata.blogspot.com/2019/04/2019-week-30.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with STRING_SPLIT

-- STEP 1
-- Only keep tweets that give water / air temperatues
-- Extract Water and Air Temperatures as separate columns

SELECT
	CASE WHEN CHARINDEX('Water - ', Text) <>  0 OR CHARINDEX('Air - ', Text) <>  0 THEN 1 ELSE 0 END AS is_temp_tweet,
	CASE WHEN PATINDEX( '%Air - [0-9][0-9].[0-9]%', Text) <> 0 THEN 1 ELSE 0 END AS is_temptweet_2,
--	PATINDEX ( '%Water - %', Text) as pat_index,
--	CHARINDEX('Water - ', Text) AS char_index,
	SUBSTRING(Text, CHARINDEX('Water - ', Text) + 8, 13) as Water_temp,
--	SUBSTRING(Text, CHARINDEX('Water - ', Text) + 16, 4) as test,
	SUBSTRING(Text, CHARINDEX('Air - ', Text) + 6, 13) as Air_temp,
--	SUBSTRING(Text, CHARINDEX('Air - ', Text) + 14, 4) as Air_temp_C,
	Text AS Comment,
	RIGHT([Text], LEN (Text) - PATINDEX( '%Air - [0-9][0-9].[0-9]%', Text) - 19 ) as pat_index,
	Tweet_Id,
	Created_At
--	Screen_Name,
--	Favorites,
--	Name,
--	Retweets,
--	[Language],
--	Client,
--	Tweet_Type,
--	Media_Type,
--	URLs,
--	Hashtags,
--	Mentions
FROM
	pd2019w30_tweets
WHERE 	CHARINDEX('Water - ', Text) <>  0 OR CHARINDEX('Air - ', Text) <>  0 -- Remove tweets without temperature
;


