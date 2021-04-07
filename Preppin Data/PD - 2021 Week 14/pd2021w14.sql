-- Preppin Data
-- 2021 Week 14
-- https://preppindata.blogspot.com/2021/03/2021-week-14.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with LATERAL, CROSS JOIN and VALUES 
-- https://stackoverflow.com/questions/1128737/unpivot-and-postgresql, https://dbfiddle.uk/?rdbms=postgres_11&fiddle=f20c22097dad9b37e77ee19769e96cbb
-- Regular Expressions 
-- Temporary tables (similar to T-SQL)
-- CAST
-- Export data to Excel

-- STEP 1
-- Unpivot the seats table, add seat type and store the data into a newseats temp table

DROP TABLE IF EXISTS newseats;
WITH Unpivoted AS (
	SELECT
		sl."Row_no",
		seat_letter,
		seat_number
	FROM
		pd2021w14_seat_list_csv sl
	CROSS JOIN LATERAL (
	VALUES ('A',sl.a),('B',sl.b),('C',sl.c),('D',sl.d),('E',sl.e),('F',sl.f)) AS s(seat_letter, seat_number)
)
SELECT 
	*,
	CASE 
	WHEN seat_letter = 'A' OR seat_letter = 'F' THEN 'Window'
	WHEN seat_letter = 'B' OR seat_letter = 'E' THEN 'Middle'
	WHEN seat_letter = 'C' OR seat_letter = 'D' THEN 'Aisle'
	ELSE 'Check'
	END AS Seat_type
INTO TEMPORARY TABLE newseats -- creates new temp table
FROM Unpivoted
;

--SELECT * FROM newseats; -- Test

-- STEP 2
-- Parse flight details, classify flight times and put it into a new_flight_details temp table

DROP TABLE IF EXISTS new_flight_details;
WITH Parsed AS (
		SELECT 
	--		*,
			CAST( ((regexp_match(details, '\d+'))[1]) AS INT) AS flight,
			LEFT(((regexp_match(details, '\w{3}\|\w{3}'))[1]),3) AS origin,
			RIGHT(((regexp_match(details, '\w{3}\|\w{3}'))[1]),3) AS destination,
			(regexp_match(details, '\d{4}-\d{2}-\d{2}'))[1] AS flight_date,
			(regexp_match(details, '\d{2}:\d{2}:\d{2}'))[1] AS flight_time
		FROM pd2021w14_flight_details_csv 
)
SELECT 
	*, 
	CASE 
	WHEN CAST( LEFT(flight_time,2) AS INT) < 12 THEN 'Morning'
	WHEN CAST( LEFT(flight_time,2) AS INT) > 12 AND CAST( LEFT(flight_time,2) AS INT) < 18 THEN 'Afternoon'
	WHEN CAST( LEFT(flight_time,2) AS INT) > 18 THEN 'Evening'
	ELSE 'Check' END AS flight_when
INTO TEMPORARY TABLE new_flight_details
FROM Parsed
;	
--SELECT * FROM new_flight_details; -- Test

-- STEP 3
-- Define Business Class seats in a new_plane_details temp table

DROP TABLE IF EXISTS new_plane_details;
SELECT
	"FlightNo.",
	"Business Class",
	CAST( SUBSTRING("Business Class", 3) AS INT) AS business_class_max
INTO TEMPORARY TABLE new_plane_details
FROM
	public.pd2021w14_plane_details_csv
;
--SELECT * FROM new_plane_details; -- Test

-- STEP 4
--Combine the Passenger List table with New Seat List, New Flight Details and New Plane Details

DROP TABLE IF EXISTS All_Combined;
SELECT
	pl.first_name,
	pl.last_name,
	pl.passenger_number,
	pl.flight_number,
	pl.purchase_amount,
	ns."Row_no",
	ns.seat_letter,
--	ns.seat_number,
	ns.seat_type,
--	fd.flight,
	fd.origin,
	fd.destination,
	fd.flight_date,
	fd.flight_time,
	fd.flight_when,
--	pd."FlightNo.",
--	pd."Business Class",
	pd.business_class_max,
	CASE WHEN ns."Row_no" <= pd.business_class_max THEN 'Business' ELSE 'Economy' END AS seat_class
INTO TEMPORARY TABLE All_Combined
FROM 		pd2021w14_passenger_list_csv pl
INNER JOIN 	newseats ns 			ON pl.passenger_number = ns.seat_number
INNER JOIN 	new_flight_details fd 	ON pl.flight_number = fd.flight
INNER JOIN 	new_plane_details pd 	ON pl.flight_number = pd."FlightNo."
;

--SELECT * FROM All_Combined ORDER BY flight_number, passenger_number; -- Test

-- STEP 5 Get the final results from the combined table in three separate queries

-- 1. What time of day were the most purchases made? (Avg per flight)

--COPY (
WITH Agg_purchases AS (
		SELECT 
			flight_number,
			flight_when,
			SUM(purchase_amount) AS purchases 
		FROM All_Combined
		WHERE 
			seat_class = 'Economy'
		GROUP BY 
			flight_number, 
			flight_when
)
SELECT 
	ROW_NUMBER() OVER (ORDER BY AVG(purchases) DESC) AS Rank1,
	flight_when AS Depart_time_of_the_day,
	CAST( AVG(purchases) AS DECIMAL (7,2)) AS Purchase_amount 
FROM Agg_purchases
GROUP BY 
	flight_when
ORDER BY 
	AVG(purchases) DESC
--) TO 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2021 Week 14\Output\time_of_day.csv' DELIMITER ',' CSV HEADER
;

-- 2. What seat position had the highest purchase amount? 
--COPY (
SELECT 
	ROW_NUMBER() OVER (ORDER BY SUM(purchase_amount) DESC) AS Rank1,	
	seat_type as seat_position,
	SUM(purchase_amount) AS purchase_amount
FROM All_Combined
WHERE 
	seat_class = 'Economy'
GROUP BY
	seat_type
ORDER BY 
	SUM(purchase_amount) DESC
--) TO 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2021 Week 14\Output\seat_position.csv' DELIMITER ',' CSV HEADER
;

-- 3. Business class purchases are free. How much is this costing us?

--COPY (
SELECT 
	ROW_NUMBER() OVER (ORDER BY SUM(purchase_amount) DESC) AS Rank1,
	seat_class,
	SUM(purchase_amount) AS purchase_amount
FROM All_Combined
GROUP BY
	seat_class
ORDER BY 
	SUM(purchase_amount) DESC
--) TO 'C:\Users\jorge\Documents\MEGAsync\SQL\Challenges and projects\Preppin Data\PD - 2021 Week 14\Output\business_class.csv' DELIMITER ',' CSV HEADER
;
