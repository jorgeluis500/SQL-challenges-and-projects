-- https://preppindata.blogspot.com/2019/02/2019-week-3.html

SELECT
	DATE_ADD(cj.Start_Date_2,INTERVAL cj.Length MONTH) AS Payment_date,
	cj.Name,
    cj.Monthly_Cost,
    cj.`Contract_Length_(months)`,
    cj.Start_Date_2
FROM
(
SELECT 
	*,
    str_to_date(Start_Date, '%d-%m-%Y') as Start_date_2
FROM 2019w3a
CROSS JOIN 2019w3b
WHERE 
	Length <= `Contract_Length_(months)` 
ORDER BY
	Name,
	Length
) as cj
 
ORDER BY
	cj.Name,
	Payment_date
;