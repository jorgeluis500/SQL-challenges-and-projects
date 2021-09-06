-- Preppin Data
-- 2021 Week 30
-- https://preppindata.blogspot.com/2021/07/2021-week-30-lift-your-spirits.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Cross join
-- make_timestamp
-- window functions

-- STEP 1
-- Create a TripID field based on the time of day
	-- Assume all trips took place on 12th July 2021
-- Create numberred floor

DROP TABLE IF EXISTS t_numbered;
CREATE TEMPORARY TABLE t_numbered AS
SELECT
	make_timestamp(2021, 07, 12, date_hour, day_min, 0) AS trip_date,
	date_hour,
	day_min,
	from_floor,
	to_floor,
		CASE 
			WHEN from_floor = 'B' THEN 1
		WHEN from_floor = 'G' THEN 2
		ELSE CAST(from_floor AS INT) + 2
	END AS from_floor_number,
		CASE 
			WHEN to_floor = 'B' THEN 1
		WHEN to_floor = 'G' THEN 2
		ELSE CAST(to_floor AS INT) + 2
	END AS to_floor_number
FROM
	public.pd2021w30_lift_data
;
--select * from t_numbered; -- Test

--STEP 2 
-- Calculate default floor

DROP TABLE IF EXISTS t_default;
CREATE TEMPORARY TABLE t_default AS 
SELECT
	from_floor AS default_floor,
	from_floor_number AS default_floor_number,
	count(*) AS records
FROM
	t_numbered
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1
;

--STEP 3
-- Join with default floor
-- Create trip id
-- Calculate travelleld floors

DROP TABLE IF EXISTS t_travels;
CREATE TEMPORARY TABLE t_travels AS
SELECT
	ROW_NUMBER() OVER(ORDER BY trip_date ASC) AS trip_id,
	n.trip_date,
	n.date_hour,
	n.day_min,
	n.from_floor,
	n.to_floor,
	n.from_floor_number,
	n.to_floor_number,
--	ABS(n.from_floor_number - n.to_floor_number) AS current_travelled,
	d.default_floor,
	d.default_floor_number,
	LEAD(n.from_floor_number,1) OVER (ORDER BY trip_date asc) AS next_trip,
	ABS(LEAD(n.from_floor_number,1) OVER (ORDER BY trip_date asc) - to_floor_number) AS travel_between_trips,
--	d.records,
	ABS(d.default_floor_number - n.to_floor_number) AS travel_from_default
FROM
	t_numbered n
CROSS JOIN t_default d;

--SELECT * FROM t_travels; -- TEST

-- STEP 4
-- Calculate average travels

SELECT
	default_floor,
	round(avg(travel_from_default),2) AS avg_travel_from_default_position,
	round(avg(travel_between_trips),2) AS avg_travel_between_trips_currently,
	round(avg(travel_from_default) - avg(travel_between_trips),2) AS difference
FROM
	t_travels
GROUP BY 1
;