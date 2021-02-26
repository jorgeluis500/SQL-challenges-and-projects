-- https://preppindata.blogspot.com/2019/02/2019-week-2.html

SELECT * FROM 2019w2;

SELECT  
	CASE 
		WHEN City LIKE '%Lond%' THEN 'London' 
		WHEN City LIKE '%burg%' THEN 'Edinburg'	
		WHEN City LIKE '%nod%' THEN 'London'
		WHEN City LIKE '%edi%' THEN 'Edinburg'
		ELSE 'Check'
	END AS City_corrected, 
	Date,
	SUM(CASE WHEN Metric = 'Wind speed' THEN Value ELSE 0 END) AS 'Wind_speed_-_mph',
    SUM(CASE WHEN Metric = 'Max Temperature' THEN Value ELSE 0 END) AS 'Max_Temperature_-_Celsius',
	SUM(CASE WHEN Metric = 'Min Temperature' THEN Value ELSE 0 END) AS 'Min Temperature_-_Celsius',
	SUM(CASE WHEN Metric = 'Precipitation' THEN Value ELSE 0 END) AS 'Precipitation_-_mm'
	 FROM 2019w2
GROUP BY
	City_corrected,
	Date
ORDER BY
	City_corrected,
	Date
;