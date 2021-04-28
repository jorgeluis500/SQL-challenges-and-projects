-- Preppin Data
-- 2021 Week 17
-- https://preppindata.blogspot.com/2021/03/2021-week-17.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Unpivot with CROSS JOIN and LATERAL VALUES
-- Substring with Regular expressions (to split strings)
-- Format numbers as percentage
-- WITH clause (in addition to temp tables)
-- Query format in lower case

-- STEP 1
-- Remove the totals
-- Remove the "Annual Leave" value and cast that field as float

drop table if exists temp_floats;
create temporary table temp_floats AS
select
	"Name, Age, Area of Work",
	project,
	"2/1/2021" ,
	"2/2/2021" ,
	"2/3/2021" ,
	"2/4/2021" ,
	"2/5/2021" ,
	"2/8/2021" ,
	"2/9/2021" ,
	"2/10/2021",
	"2/11/2021",
	cast( case when "2/12/2021" = 'Annual Leave' then null else "2/12/2021" end as float)
from
	public.pd2021w17_csv
where 
	"Name, Age, Area of Work" is not null
;
--select * from temp_floats; -- Test

-- STEP 2
-- Unpivpot with LATERAL CROSS JOIN and VALUES
-- Get Name, Age and Area of work with SUBSTRING and Regex

drop table if exists temp_unpivoted;
create temporary table temp_unpivoted as 
select 
--	"Name, Age, Area of Work",
	substring("Name, Age, Area of Work", '\w*') as p_name,
	substring("Name, Age, Area of Work", '\d{2}') as p_age,
	substring("Name, Age, Area of Work", ':\s(.*)') as area_of_work,
	project,
	dates,
	hours
from temp_floats u
cross join lateral (
values 
(cast( '2021-01-02' as date), u."2/1/2021"),
(cast( '2021-02-02' as date), u."2/2/2021"),
(cast( '2021-03-02' as date), u."2/3/2021"),
(cast( '2021-04-02' as date), u."2/4/2021"),
(cast( '2021-05-02' as date), u."2/5/2021"),
(cast( '2021-08-02' as date), u."2/8/2021"),
(cast( '2021-09-02' as date), u."2/9/2021"),
(cast( '2021-10-02' as date), u."2/10/2021" ),
(cast( '2021-11-02' as date), u."2/11/2021" ),
(cast( '2021-12-02' as date), u."2/12/2021" )

) as t(dates, hours)
where hours is not null
;

--select * from temp_unpivoted; -- Test

-- STEP 3
-- a. Get the total hours
-- b. Get the hours worked in clients
-- c. join both tables

--a. total hours
with total_hours as (
		select 
			p_name,
			sum(hours) / count(distinct dates) AS avg_number_of_hours_worked_per_day
		from temp_unpivoted
		group by
		p_name
)

--b. hours with clients
, client_work as (
		select 
			p_name,
			'Client' as area_of_work,
			to_char( (sum(CASE WHEN area_of_work = 'Client' THEN hours ELSE 0 END) * 100 / sum(hours) ), '999%') AS perc_of_total
		from temp_unpivoted
		where area_of_work <> 'Chats'
		group by
		p_name
)

--c. join both tables

select
	th.p_name,
	cw.area_of_work,
	cw.perc_of_total,
	th.avg_number_of_hours_worked_per_day
from
	total_hours th
inner join client_work cw 
	on th.p_name = cw.p_name
;
