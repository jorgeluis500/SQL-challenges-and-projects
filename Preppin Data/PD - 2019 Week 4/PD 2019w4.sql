USE preppindata;

SELECT 
	CASE WHEN LEFT(Opponent,2) = 'vs' THEN replace(Opponent,'vs','') 
		 WHEN LEFT(Opponent,1) = '@' THEN replace(Opponent,'@','')
         ELSE 'Check'
         END AS Opponent_clean,         
    SUBSTRING_INDEX(HI_POINTS,' ',1) AS HI_POINTS_Player,
    SUBSTRING_INDEX(HI_POINTS,' ',-1) AS HI_POINTS_Value,
    SUBSTRING_INDEX(HI_REBOUNDS,' ',1) AS HI_REBOUNDS_Player,
    SUBSTRING_INDEX(HI_REBOUNDS,' ',-1) AS HI_REBOUNDS_Value,
    SUBSTRING_INDEX(HI_ASSISTS,' ',1) AS HI_ASSISTS_Player,
    SUBSTRING_INDEX(HI_ASSISTS,' ',-1) AS HI_ASSISTS_Value,
    LEFT(RESULT,1) AS Win_or_loss,
    CASE WHEN LEFT(Opponent,2) = 'vs' THEN 'Home' 
		 WHEN LEFT(Opponent,1) = '@' THEN 'Away'
         ELSE 'Check'
         END AS Home_or_Away,
	-- date,
    -- CASE WHEN MONTH(str_to_date(MID(date,6,8),'%b')) >= 10 THEN 2018 ELSE 2019 END AS Season_year,
    -- MONTH(str_to_date(MID(date,6,8),'%b')) as Month_of_year,
	-- SUBSTRING_INDEX(MID(date,6,8), ' ',-1) AS Day_of_date,
    STR_TO_DATE(CONCAT(CASE WHEN MONTH(str_to_date(MID(date,6,8),'%b')) >= 10 THEN 2018 ELSE 2019 END, '-',MONTH(str_to_date(MID(date,6,8),'%b')), '-', SUBSTRING_INDEX(MID(date,6,8), ' ',-1)),'%Y-%m-%d') AS True_date,
    Opponent,
    Result,
    W_L
FROM
    2019w4
WHERE
    DATE <> ''