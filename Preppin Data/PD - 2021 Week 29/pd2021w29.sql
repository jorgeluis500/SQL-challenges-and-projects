-- Preppin Data
-- 2021 Week 29
-- https://preppindata.blogspot.com/2021/07/2021-week-29-pd-x-wow-tokyo-2020.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- bitwise operatot NOT. 
-- Date and datetime parsing

-- STEP 1
--  Create a correctly formatted DateTime field 

drop table if exists t_parsed_date;
create temporary table t_parsed_date as 
with pd1 as (
	select
		event_date,
		cast( substring(event_date, '\d+') as int) as date_day,
		case 
			when replace(substring(event_date, '_\w+_'),'_','') = 'July' then 7
			when replace(substring(event_date, '_\w+_'),'_','') = 'August' then 8
			else 0
		end as date_month,
		cast( right(event_date, 4) as int) as date_year,
		event_time,
		case 
			when split_part(event_time,':', 1) ~ '^[0-9\.]+$' -- checks if the result is a number
			then cast( split_part(event_time,':', 1) as int) 
			else null
		end as hr,
		case 
			when split_part(event_time,':', 2) ~ '^[0-9\.]+$' -- checks if the result is a number
			then cast( split_part(event_time,':', 2) as int) 
			else null
		end as minutes,
		sport,
		case 
		when sport = 'Softball/Baseball' then 'Baseball/Softball'
		when sport = 'Softball' then 'Baseball/Softball'
		when sport = 'Baseball' then 'Baseball/Softball'
		when sport = 'Artistic Gymnastic' then 'Artistic Gymnastics'
		when sport = 'Beach Volleybal' then 'Beach Volleyball'
		when sport = 'Beach Volley' then 'Beach Volleyball'
		when sport = 'Cycling Bmx Freestyle' then 'Cycling BMX Freestyle'
		when sport = 'Cycling Bmx Racing' then 'Cycling BMX Racing'
		when sport = 'Cycling Mountain Bike' then 'Cycling Mountain Bike'
		else sport
		end as joining_sport,
		venue,
		lower(venue) as joining_venue,
		events
	from
		pd2021w29_events_csv
)
select
	*
	, make_date(date_year, date_month, date_day) as new_date
	, make_timestamp(date_year, date_month, date_day, hr, minutes,00) as UK_date_time
from
	pd1
;
--select * from t_parsed_date; -- Test

-- STEP 2
--Parse the event list so each event is on a separate row 

drop table if exists t_unpivoted;
create temporary table t_unpivoted as
select
	*,
	trim(unnest(string_to_array(events,','))) as events_in_rows
from t_parsed_date
;
--select * from t_unpivoted; -- Test

--STEP 3
-- Group similar sports into a Sport Type field 
-- Clean, capitalize and remove the dot from the sport field. 
	-- Created as a new field since the grouping was already done when I realized this needed to be cleaned
	-- Otherwise the join with the venue would not work

--select distinct sport from t_unpivoted order by 1;
-- copy pasted in Excel to create the CASE statement

drop table if exists t_grouped;
create temporary table t_grouped as
select 
	*,
	CASE
	     WHEN sport = '3x3 Basketball' THEN  'Basketball'
	     WHEN sport = 'Archery' THEN  'Archery'
	     WHEN sport = 'Artistic Gymnastic' THEN  'Gymnastics'
	     WHEN sport = 'Artistic Gymnastics' THEN  'Gymnastics'
	     WHEN sport = 'Artistic Swimming' THEN  'Swimming'
	     WHEN sport = 'Athletics' THEN  'Athletics'
	     WHEN sport = 'Badminton' THEN  'Badminton'
	     WHEN sport = 'Baseball' THEN  'Baseball/Softball'
	     WHEN sport = 'Baseball/Softball' THEN  'Baseball/Softball'
	     WHEN sport = 'Basketball' THEN  'Basketball'
	     WHEN sport = 'Beach Volley' THEN  'Volleyball'
	     WHEN sport = 'Beach Volleybal' THEN  'Volleyball'
	     WHEN sport = 'Beach volleyball' THEN  'Volleyball'
	     WHEN sport = 'Beach Volleyball' THEN  'Volleyball'
	     WHEN sport = 'boxing' THEN  'Boxing'
	     WHEN sport = 'Boxing' THEN  'Boxing'
	     WHEN sport = 'Boxing.' THEN  'Boxing'
	     WHEN sport = 'Canoe Slalom' THEN  'Canoe'
	     WHEN sport = 'Canoe Sprint' THEN  'Canoe'
	     WHEN sport = 'Closing Ceremony' THEN  'Ceremony'
	     WHEN sport = 'Cycling BMX Freestyle' THEN  'Cycling'
	     WHEN sport = 'Cycling BMX Racing' THEN  'Cycling'
	     WHEN sport = 'Cycling Mountain Bike' THEN  'Cycling'
	     WHEN sport = 'Cycling Road' THEN  'Cycling'
	     WHEN sport = 'Cycling Track' THEN  'Cycling'
	     WHEN sport = 'diving' THEN  'Diving'
	     WHEN sport = 'Diving' THEN  'Diving'
	     WHEN sport = 'Equestrian' THEN  'Equestrian'
	     WHEN sport = 'Fencing' THEN  'Fencing'
	     WHEN sport = 'football' THEN  'Football'
	     WHEN sport = 'Football' THEN  'Football'
	     WHEN sport = 'Golf' THEN  'Golf'
	     WHEN sport = 'Handball' THEN  'Handball'
	     WHEN sport = 'Hockey' THEN  'Hockey'
	     WHEN sport = 'Judo' THEN  'Martial Arts'
	     WHEN sport = 'Karate' THEN  'Martial Arts'
	     WHEN sport = 'Marathon Swimming' THEN  'Swimming'
	     WHEN sport = 'Modern Pentathlon' THEN  'Modern Pentathlon'
	     WHEN sport = 'Opening Ceremony' THEN  'Ceremony'
	     WHEN sport = 'Rhythmic Gymnastics' THEN  'Gymnastics'
	     WHEN sport = 'Rowing' THEN  'Rowing'
	     WHEN sport = 'rugby' THEN  'Rugby'
	     WHEN sport = 'Rugby' THEN  'Rugby'
	     WHEN sport = 'Rugby.' THEN  'Rugby'
	     WHEN sport = 'Sailing' THEN  'Sailing'
	     WHEN sport = 'Shooting' THEN  'Shooting'
	     WHEN sport = 'Skateboarding' THEN  'Skateboarding'
	     WHEN sport = 'Skateboarding.' THEN  'Skateboarding'
	     WHEN sport = 'Softball' THEN  'Baseball/Softball'
	     WHEN sport = 'Softball/Baseball' THEN  'Baseball/Softball'
	     WHEN sport = 'Sport Climbing' THEN  'Sport Climbing'
	     WHEN sport = 'Surfing' THEN  'Surfing'
	     WHEN sport = 'Swimming' THEN  'Swimming'
	     WHEN sport = 'Table Tennis' THEN  'Table Tennis'
	     WHEN sport = 'Taekwondo' THEN  'Martial Arts'
	     WHEN sport = 'Tennis' THEN  'Tennis'
	     WHEN sport = 'Trampoline Gymnastics' THEN  'Gymnastics'
	     WHEN sport = 'Triathlon' THEN  'Triathlon'
	     WHEN sport = 'volleyball' THEN  'Volleyball'
	     WHEN sport = 'Volleyball' THEN  'Volleyball'
	     WHEN sport = 'Water Polo' THEN  'Water Polo'
	     WHEN sport = 'Weightlifting' THEN  'Weightlifting'
	     WHEN sport = 'Wrestling' THEN  'Wrestling'
	     WHEN sport = 'Wrestling.' THEN  'Wrestling'
	end as sport_group,
	Replace( trim( initcap( joining_sport ) ), '.', '' ) as sport_clean -- removes the dot, cleans and capitalize a new sport field
from t_unpivoted t1
;
--select * from t_grouped; -- Test

-- STEP 4
-- Combine the Venue table 
-- Select relevant fields and create the god medal or ceremony field

with venues2 as (
select
	*,
	case 
		when sport like 'Basket%' then 'Basketball'
		else sport 
	end as joining_sport,	
	lower(venue) as joining_venue,
	split_part(lat_lon, ', ', 1) as latitude,
	split_part(lat_lon, ', ', 2) as longitude
from pd2021w29_venues_csv
)
, t_events3 as  (
select
	t1.event_date,
	t1.date_day,
	t1.date_month,
	t1.date_year,
	t1.event_time,
	t1.hr,
	t1.minutes,
	t1.sport as sport1,
	t1.joining_sport as joining_sport1,
	t1.venue as venue1,
	t1.joining_venue as joining_venue1,
	t1.events,
	t1.new_date,
	t1.uk_date_time,
	t1.events_in_rows,
	t1.sport_group,
	t1.sport_clean,
	t2.venue as venue2,
	t2.sport as sport2,
	t2.lat_lon,
	t2.joining_sport as joining_sport2,
	t2.joining_venue as joining_venue2,
	t2.latitude,
	t2.longitude,
	case 
		when events_in_rows like '%Gold Medal%' then true
		when events_in_rows like '% Ceremony' then true
		else false 
	end as medal_ceremony
from
	t_grouped t1
left join venues2 t2
	on t1.joining_venue = t2.joining_venue
	and t1.sport_clean = t2.joining_sport
)
-- TEST
-- select * from t_events3
--where lat_lon is not null; -- to check for rows not joining
select
	latitude,
	longitude,
	medal_ceremony,
	sport_group,
	events_in_rows as events_splits,
	uk_date_time,
	new_date,
	sport_clean,
	venue1
--	event_date,
--	date_day,
--	date_month,
--	date_year,
--	event_time,
--	hr,
--	minutes,
--	sport1,
--	joining_sport1,
--	joining_venue1,
--	events,
--	venue2,
--	sport2,
--	lat_lon,
--	joining_sport2,
--	joining_venue2,
from t_events3
order by 
	uk_date_time;
	
-- There are 10 rows that did not join properly, the opnes for Cycling BMX events