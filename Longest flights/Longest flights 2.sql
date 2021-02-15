CREATE DATABASE longest_flights;

USE longest_flights;

-- Explore the data
SELECT * from flights;
SELECT * from worldcities;

-- Parse text in columns

SELECT
`Rank`,
CASE WHEN LOCATE('–JFK', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('–JFK', `From`)-1) 
	WHEN LOCATE('/', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('/', `From`)-1)
    WHEN LOCATE('–Heathrow', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('–Heathrow', `From`)-1)
    ELSE `From` END AS Origin,
CASE WHEN LOCATE('–JFK', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('–JFK', `To`)-1) 
	WHEN LOCATE('/', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('/', `To`)-1)
    WHEN LOCATE('–Heathrow', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('–Heathrow', `To`)-1)
    ELSE `To` END AS Destination,
REPLACE(SUBSTRING(Distance, 1, LOCATE('km', Distance)-1),',','') AS Distance_km,
REPLACE(SUBSTRING(Distance, locate('(', Distance)+1, 6),',','') AS Distance_mi,
Duration,
Aircraft,
CASE WHEN LOCATE('[', `First flight`) <> 0 THEN SUBSTRING(`First flight`, 1, LOCATE('[', `First flight`)-1)
	ELSE `First flight`
    END AS First_flight
FROM flights
;

-- Test to rank the cities

SELECT * FROM 
(
SELECT 
	city_ascii,
	population,
    country,
    lat,
    lng,
    ROW_NUMBER() OVER (PARTITION BY city_ascii ORDER BY city_ascii, population desc) as pop_rank
FROM worldcities 
) as rc
WHERE pop_rank = 1 
;

-- Final Query
-- (Rank, Origin, Destination, Distance_km, Distance_mi, Duration, Aircraft, First_flight) 

WITH flights_2 AS (
	SELECT
	`Rank`,
	CASE WHEN LOCATE('–JFK', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('–JFK', `From`)-1) 
		WHEN LOCATE('/', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('/', `From`)-1)
		WHEN LOCATE('–Heathrow', `From`) <> 0 THEN SUBSTRING(`From`, 1, LOCATE('–Heathrow', `From`)-1)
		ELSE `From` END AS Origin,
	CASE WHEN LOCATE('–JFK', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('–JFK', `To`)-1) 
		WHEN LOCATE('/', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('/', `To`)-1)
		WHEN LOCATE('–Heathrow', `To`) <> 0 THEN SUBSTRING(`To`, 1, LOCATE('–Heathrow', `To`)-1)
		ELSE `To` END AS Destination,
	REPLACE(SUBSTRING(Distance, 1, LOCATE('km', Distance)-1),',','') AS Distance_km,
	REPLACE(SUBSTRING(Distance, locate('(', Distance)+1, 6),',','') AS Distance_mi,
	Duration,
	Aircraft,
	CASE WHEN LOCATE('[', `First flight`) <> 0 THEN SUBSTRING(`First flight`, 1, LOCATE('[', `First flight`)-1)
		ELSE `First flight`
		END AS First_flight
	FROM flights ),
wcities AS 
(
SELECT city_ascii, lat, lng FROM 
(
SELECT 
	city_ascii,
	population,
    country,
    lat,
    lng,
    ROW_NUMBER() OVER (PARTITION BY city_ascii ORDER BY city_ascii, population desc) as pop_rank
FROM worldcities 
) as rc
WHERE pop_rank = 1 
    ),

wcities2 AS 
(
SELECT city_ascii, lat, lng FROM 
(
SELECT 
	city_ascii,
	population,
    country,
    lat,
    lng,
    ROW_NUMBER() OVER (PARTITION BY city_ascii ORDER BY city_ascii, population desc) as pop_rank
FROM worldcities 
) as rc
WHERE pop_rank = 1 
    ) 

SELECT 
	flights_2.*,
	wcities.lat AS O_lat,
	wcities.lng AS O_lng,
	wcities2.lat AS D_lat,
	wcities2.lng AS D_lng
FROM flights_2
LEFT JOIN  wcities
	ON flights_2.Origin = wcities.city_ascii
LEFT JOIN  wcities2
	ON flights_2.Destination = wcities2.city_ascii
;

