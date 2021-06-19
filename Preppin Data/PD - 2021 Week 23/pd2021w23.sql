-- Preppin Data
-- 2021 Week 23
-- https://preppindata.blogspot.com/2021/06/2021-week-23-nps-for-airlines.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Window Functions
-- Common table expressions (CTEs)
-- Aggregations
-- Std deviation

-- STEP 1
-- Combine Prep Air dataset with other airlines

DROP TABLE IF EXISTS t_unioned;
CREATE TEMPORARY TABLE t_unioned AS 
	SELECT * FROM pd2021w23_prepair 
	UNION ALL
	SELECT * FROM pd2021w23_airlines 
;
-- SELECT * FROM t_unioned; -- Test

-- STEP 2
-- Exclude any airlines who have had less than 50 customers respond
-- Classify customer responses to the question in the following way:
	--0-6 = Detractors
	--7-8 = Passive
	--9-10 = Promoters

DROP TABLE IF EXISTS t_classified;
CREATE TEMPORARY TABLE t_classified AS 
	WITH num_cust AS (
		SELECT 
			*, 
			COUNT(*) OVER(PARTITION BY "Airline") AS cust_per_airline
		FROM t_unioned
		)
SELECT 
	*, 
	CASE 
		WHEN "How_likely_are_you_to_recommend_this_airline" <=6 THEN 'Detractor' 
		WHEN "How_likely_are_you_to_recommend_this_airline" <=8 THEN 'Passive'
		WHEN "How_likely_are_you_to_recommend_this_airline" <=10 THEN 'Promoter'
	ELSE 'Check' END AS response_type
FROM num_cust 
WHERE 
	cust_per_airline >= 50
;
--SELECT * FROM t_classified; -- Test

-- STEP 3
-- Calculate percentage of promotes and detractors
-- Calculate the NPS for each airline
	--	NPS = % Promoters - % Detractors

DROP TABLE IF EXISTS t_nps;
CREATE TEMPORARY TABLE t_nps AS 
	WITH t_percentages AS (
		SELECT
			"Airline",
			COUNT(*) AS number_of_responses,
			SUM(CASE WHEN response_type = 'Promoter' THEN 1 ELSE 0 END) AS promoters,
			SUM(CASE WHEN response_type = 'Detractor' THEN 1 ELSE 0 END) AS detractors,
			ROUND(SUM(CASE WHEN response_type = 'Promoter' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2 ) AS percent_promoters,
			ROUND(SUM(CASE WHEN response_type = 'Detractor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2 ) AS percent_detractors
		FROM t_classified
		GROUP BY 
			"Airline"
)
SELECT 
	*, 
	percent_promoters - percent_detractors AS NPS
FROM t_percentages
;
-- SELECT * FROM t_nps; -- Test

-- STEP 4
-- Calculate the average and standard deviation of the dataset
-- Take each airline's NPS and subtract the average, then divide this by the standard deviation
-- (To match the official result, the std dev of the sample must be used)

WITH t_avg_stddev AS ( 
	SELECT 
		*,
		AVG(nps) OVER () AS avg_nps,
		stddev_samp(nps) OVER () AS stdev_nps
	FROM t_nps
)
SELECT 
	"Airline",
	nps,
	(nps - avg_nps) / stdev_nps AS z_score
FROM t_avg_stddev
WHERE
	"Airline" = 'Prep Air'
;