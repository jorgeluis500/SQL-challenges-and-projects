-- Preppin Data
-- 2019 Week 5 - File 1
-- https://preppindata.blogspot.com/2019/03/2019-week-5.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Text functions
-- CASE Statements



	 SELECT 
/*		 '2019-06-17' AS Start_date,
         Date,
         CASE 	WHEN Date = 'Monday' THEN 0
				WHEN Date = 'Tuesday' THEN 1
				WHEN Date = 'Wednesday' THEN 2
                WHEN Date = 'Thursday' THEN 3
                WHEN Date = 'Friday' THEN 4
                END AS Day_number, 
*/		date_add('2019-06-17', INTERVAL CASE 	WHEN Date = 'Monday' THEN 0
				WHEN Date = 'Tuesday' THEN 1
				WHEN Date = 'Wednesday' THEN 2
                WHEN Date = 'Thursday' THEN 3
                WHEN Date = 'Friday' THEN 4
                END DAY) AS Real_date,
		CASE WHEN Notes LIKE 'Call%' THEN 'Call'
			 WHEN Notes LIKE 'Email%' THEN 'Email' ELSE 'Check' END AS Contact_method,
		CASE WHEN Notes LIKE '%statement%' THEN 1 ELSE 0 END AS Statement,
        CASE WHEN Notes LIKE '%balance%' THEN 1 ELSE 0 END AS Balance,
        CASE WHEN Notes LIKE '%complaint%' THEN 1 ELSE 0 END AS Complaint,
        Customer_ID,
        SUBSTRING(Notes, LOCATE('#',Notes)+1, 4) AS Policy
        -- CASE WHEN LOCATE('#',Notes) = 0 THEN FALSE ELSE TRUE END AS Contains_policy
       -- Notes
FROM 2019w5a
    WHERE Customer_ID <> 99999
    AND CASE WHEN LOCATE('#',Notes) = 0 THEN 0 ELSE 1 END <> 0
UNION
SELECT 
/*	 '2019-06-24' AS Start_date,
        Date,
        CASE 	WHEN Date = 'Monday' THEN 0
				WHEN Date = 'Tuesday' THEN 1
				WHEN Date = 'Wednesday' THEN 2
                WHEN Date = 'Thursday' THEN 3
                WHEN Date = 'Friday' THEN 4
                END AS Day_number,
 */      date_add('2019-06-24', INTERVAL CASE 	WHEN Date = 'Monday' THEN 0
				WHEN Date = 'Tuesday' THEN 1
				WHEN Date = 'Wednesday' THEN 2
                WHEN Date = 'Thursday' THEN 3
                WHEN Date = 'Friday' THEN 4
                END DAY) AS Real_date,
		CASE WHEN Notes LIKE 'Call%' THEN 'Call'
			 WHEN Notes LIKE 'Email%' THEN 'Email' ELSE 'Check' END AS Contact_method,
		CASE WHEN Notes LIKE '%statement%' THEN 1 ELSE 0 END AS Statement,
        CASE WHEN Notes LIKE '%balance%' THEN 1 ELSE 0 END AS Balance,
        CASE WHEN Notes LIKE '%complaint%' THEN 1 ELSE 0 END AS Complaint,
		Customer_ID,
        SUBSTRING(Notes, LOCATE('#',Notes)+1, 4) AS Policy
		-- CASE WHEN LOCATE('#',Notes) = 0 THEN FALSE ELSE TRUE END AS Contains_policy
        -- Notes
FROM 2019w5b
WHERE 
Customer_ID <> 99999
AND CASE WHEN LOCATE('#',Notes) = 0 THEN 0 ELSE 1 END <> 0
;