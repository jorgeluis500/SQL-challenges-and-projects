-- Preppin Data
-- 2019 Week 29
-- https://preppindata.blogspot.com/2019/04/2019-week-29.html

-- SQL flavor: T-SQL

--Tables were imported with NULL values at the end. This cleaned them. Only one example shown

DROP TABLE IF EXISTS  Stage;

SELECT * 
INTO Stage
FROM pd2019w29_c_SFrequency
WHERE S_Frequency_number IS NOT NULL
;

DROP TABLE pd2019w29_c_SFrequency
;

SELECT * 
INTO pd2019w29_c_SFrequency 
FROM Stage
;

DROP TABLE Stage
;

SELECT * 
FROM pd2019w29_c_SFrequency
;


