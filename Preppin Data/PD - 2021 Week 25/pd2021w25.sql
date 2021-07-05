-- Preppin Data
-- 2021 Week 25
-- https://preppindata.blogspot.com/2021/06/2021-week-25-worst-pokemon.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Window functions (LAG)
-- Text aggregations with STRING_AGG
-- INTERSECT to get common attributes

-- STEP 1
-- Clean up the list of Gen 1 Pokémon so we have 1 row per Pokémon

DROP TABLE IF EXISTS t_gen1;
CREATE TEMPORARY TABLE t_gen1 AS 

-- This method would be the right one if we needed all the data
-- Since we only need to remove null lines, a simple filter will do (in the second option)

-- Option 1
-- Add an index

--WITH t_ranked AS (
--	SELECT
--		*,
--		ROW_NUMBER() OVER () as g_index
--	FROM public.pd2021w25_gen1
--)
--
----Get previous value for pnumber
--
--, t_lag as(
--	SELECT 
--		*,
--		LAG(pnumber) OVER (ORDER BY g_index) AS p_pnumber
--	FROM t_ranked
--)
--
---- Form a new pnumber to group by later
--
--, newpnumber as (
--	SELECT
--		*,
--		CASE WHEN pnumber IS NULL THEN p_pnumber ELSE pnumber END AS pnumber2
--	FROM t_lag 
--)
--
---- Aggregate the data
--
--SELECT
--	pnumber2,
--	string_agg(pname, ' ') as pname,
--	string_agg(ptype, ' ') as ptype
--	AVG(total) AS total,
--	AVG(hp) AS hp,
--	AVG(attack) AS attack,
--	AVG(defense) AS defense,
--	AVG(sp_atk) AS sp_atk,
--	AVG(sp_def) AS sp_def,
--	AVG(speed) AS speed
--FROM newpnumber
--GROUP BY 
--	pnumber2
--ORDER by 1
--;

-- Option 2

SELECT
	pnumber,
	pname
FROM pd2021w25_gen1
WHERE pnumber IS NOT NULL
;
--SELECT * FROM t_gen1; -- Test;

-- STEP 2
-- Clean up the Evolution Group input...
	-- Filter out Starter and Legendary Pokémon

DROP TABLE IF EXISTS t_ev_grouped;
CREATE TEMPORARY TABLE t_ev_grouped AS 

WITH ev_grouped AS (
	SELECT
		evolution_group,
		CAST( right("#",3) AS INT) AS pnumber2,
		"Starter?" AS max_starter,
		"Legendary?" AS max_leg
	FROM
		pd2021w25_evolution_group
	)

, ev_grouped2 AS (
	SELECT 
		evolution_group,
		pnumber2
	FROM ev_grouped
	WHERE 
		max_starter = 0
		AND max_leg = 0
)
-- ...so that we can join it to the Gen 1 list:

SELECT
	eg.evolution_group,
	tg.pname
FROM ev_grouped2 eg
	INNER JOIN t_gen1 tg
	ON eg.pnumber2 = tg.pnumber
;
--SELECT * FROM t_ev_grouped; -- Test

-- STEP 3
-- Using the Evolutions input, exclude any Pokémon that evolves from a Pokémon that is not part of Gen 1 
-- or can evolve into a Pokémon outside of Gen 1

DROP TABLE IF EXISTS t_fromto;
CREATE TEMPORARY TABLE t_fromto AS
WITH evol_f AS (
	SELECT
		ef.evolving_from,
		ef.evolving_to,
		g1a.pnumber AS pnumber_a,
		g1a.pname AS pname_a
	FROM pd2021w25_evolutions ef
		LEFT JOIN t_gen1 g1a
			ON g1a.pname = ef.evolving_from
)
, evol_t AS ( 
	SELECT 
		et.evolving_from,
		et.evolving_to,
		et.pnumber_a,
		et.pname_a,
		g1b.pnumber AS pnumnber_b,
		g1b.pname AS pname_b
	FROM evol_f et
		LEFT JOIN t_gen1 g1b
			ON g1b.pname = et.evolving_to
)
SELECT 
*
FROM evol_t
WHERE 
	pname_a IS NULL
	OR pname_b IS NULL
;
SELECT * FROM t_fromto; -- Test

DROP TABLE IF EXISTS t_egroups;
CREATE TEMPORARY TABLE t_egroups AS 
SELECT
	evolution_group,
	pname
FROM t_ev_grouped ef
	INNER JOIN t_fromto ft
	ON ef.pname = ft.evolving_from
UNION ALL
SELECT 
	evolution_group,
	pname
FROM t_ev_grouped ef
	INNER JOIN t_fromto ft
	ON ef.pname = ft.evolving_to
;

SELECT * FROM t_egroups; -- Test

DROP TABLE IF EXISTS t_noevols;
CREATE TEMPORARY TABLE t_noevols AS
SELECT 
	t1.evolution_group,
	t1.pname
FROM t_ev_grouped t1
LEFT JOIN t_egroups eg
	ON t1.evolution_group = eg.evolution_group
WHERE eg.evolution_group IS NULL
;

-- STEP 4
-- Exclude any Pokémon with a mega evolution, Alolan, Galarian or Gigantamax form

DROP TABLE IF EXISTS t_moreevols;
CREATE TEMPORARY TABLE t_moreevols AS

SELECT replace("name", 'Alolan ', '') AS pname FROM pd2021w25_alolan
UNION ALL
SELECT replace("name", 'Galarian ', '') AS pname FROM pd2021w25_galarian
UNION ALL
SELECT replace("name", 'Gigantamax ', '') AS pname FROM pd2021w25_gigantamax
UNION ALL
SELECT replace("name", 'Mega ', '') AS pname FROM pd2021w25_mega_evolutions
;

SELECT 
	ne.evolution_group,
	ne.pname 
FROM t_noevols ne
	INNER JOIN t_moreevols me
	ON ne.pname = me.pname
;

DROP TABLE IF EXISTS t_join9;
CREATE TEMPORARY TABLE t_join9 AS
SELECT
	t1.evolution_group,
	t1.pname
FROM t_egroups t1
	INNER JOIN t_egroups t2
	ON t1.pname = t2.pname
GROUP BY 
	t1.evolution_group,
	t1.pname
;
SELECT * FROM t_join9; -- Test