CREATE DATABASE PreppinData;

SHOW DATABASES;

USE preppindata;

SELECT * FROM 2019w1;

ALTER TABLE 2019w1 CHANGE `Red Cars` `Red_Cars` INT;
ALTER TABLE 2019w1 CHANGE `Silver Cars` `Silver_Cars` INT;
ALTER TABLE 2019w1 CHANGE `Black Cars` `Black_Cars` INT;
ALTER TABLE 2019w1 CHANGE `Blue Cars` `Blue_Cars` INT;
ALTER TABLE 2019w1 CHANGE `When Sold Month` `When_Sold_Month` INT;
ALTER TABLE 2019w1 CHANGE `When Sold Year` `When_Sold_Year` INT;

SELECT * from 2019w1;

SELECT
	Red_cars + Silver_Cars + Black_Cars + Blue_Cars AS Total_Cars,
	STR_TO_DATE(CONCAT(01, '-', When_Sold_Month, '-', When_Sold_Year),'%d-%m-%Y') AS Date,
	Dealership,
	Red_cars,
	Silver_Cars,
	Black_Cars,
	Blue_Cars
FROM 2019w1
;


