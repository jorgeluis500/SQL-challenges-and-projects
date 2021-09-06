-- Preppin Data
-- 2021 Week 32
-- https://preppindata.blogspot.com/2021/08/2021-week-32-excelling-through.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.


-- STEP 1
-- Form Flight name
-- Parse dates

DROP TABLE IF EXISTS t_parsed;
CREATE TEMPORARY TABLE t_parsed AS 
SELECT
	"Departure",
	"Destination",
	"Departure" ||' to ' || "Destination" AS flight_name,
	to_date("Date", 'dd/mm/yyyy') AS date_parsed,
	"Class",
	to_date("Date of Flight", 'dd/mm/yyyy') AS date_of_flight_parsed,
	"Ticket Sales"
FROM
	public.pd2021w32_excelling_agg;

--select * from t_parsed; -- Test

-- STEP 2
-- Workout how many days between the sale and the flight departing

DROP TABLE IF EXISTS t_days;
CREATE TEMPORARY TABLE t_days AS 
SELECT
	*,
	(date_of_flight_parsed - date_parsed) AS days_from_departure
FROM
	t_parsed
;
--select * from t_days; -- Test

-- STEP 3 
--Classify daily sales of a flight as:
	--Less than 7 days before departure
	--7 or more days before departure
-- Calculate the metrics
	--Mimic the SUMIFS and AverageIFS functions by aggregating the previous requirements fields by each Flight and Class
	--Round all data to zero decimal places

DROP TABLE IF EXISTS t_classified;
CREATE TEMPORARY TABLE t_classified AS; 
SELECT
	flight_name,
	"Class",
	ROUND(AVG(CASE WHEN days_from_departure >= 7 THEN "Ticket Sales" ELSE NULL END),0) AS sales_more_that_7_days_until_flight, -- NULLS ARE necessary not to skew the averages
	ROUND(AVG(CASE WHEN days_from_departure < 7 THEN "Ticket Sales" ELSE NULL END),0) AS avg_ticket_sales_less_that_7_days_until_flight, -- NULLS ARE necessary not to skew the averages
	SUM(CASE WHEN days_from_departure < 7 THEN "Ticket Sales" ELSE 0 END) AS avg_ticket_sales_more_that_7_days_until_flight,
	SUM(CASE WHEN days_from_departure >= 7 THEN "Ticket Sales" ELSE 0 END) AS sales_less_that_7_days_until_flight
FROM
	t_days
GROUP BY 1, 2
;

