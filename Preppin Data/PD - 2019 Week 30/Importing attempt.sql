
-- Didn't work. Data imported with Azure DS

DROP TABLE IF EXISTS pd2019w_30_tweets;
CREATE TABLE pd2019w_30_tweets 
(
	Tweet_Id VARCHAR(100),
	Text VARCHAR(1040),
	Name VARCHAR(660),
	Screen_Name VARCHAR(1000),
	Created_At VARCHAR(625),
	Favorites VARCHAR(1580),
	Retweets VARCHAR(620),
	Tweet_languange VARCHAR(310),
	Client VARCHAR(300),
	Tweet_Type VARCHAR(1570),
	Media_Type VARCHAR(20),
	URLs VARCHAR(880),
	Hashtags VARCHAR(880),
	Mentions VARCHAR(3085)
)
;

COPY pd2019w_30_tweets (
	Tweet_Id,
	Text,
	Name,
	Screen_Name ,
	Created_At,
	Favorites ,
	Retweets,
	Tweet_languange,
	Client,
	Tweet_Type,
	Media_Type,
	URLs,
	Hashtags,
	Mentions
	)
FROM 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2019 Week 30\Input\tweets.csv' 
CSV HEADER
; 

SELECT 
	* 
FROM pd2019w_30_tweets
;