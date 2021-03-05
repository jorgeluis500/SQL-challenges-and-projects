
DROP TABLE IF EXISTS test;
CREATE TEMPORARY TABLE test (Day_name VARCHAR(80), Notes VARCHAR(255));

-- Doesn't work
-- LOAD DATA LOCAL INFILE 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\pd2019week23_a.csv'
-- INTO TABLE test;

SELECT * FROM test;

