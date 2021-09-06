-- Preppin Data
-- 2021 Week 31
-- https://preppindata.blogspot.com/2021/08/2021-week-36-excelling-in-prep.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- CASE WHEN FOR pivots


-- Initial exploration

SELECT
	"Date",
	"Store",
	"Item",
	"Status",
	"Number of Items"
FROM
	pd2021w31_data_for_pivot
;

-- Create the pivots

SELECT
	"Store",
	SUM("Number of Items") AS items_sold_per_store,
	sum(CASE WHEN "Item" = 'Wheels' THEN "Number of Items" ELSE 0 END) AS wheels,
	sum(CASE WHEN "Item" = 'Tyres' THEN "Number of Items" ELSE 0 END) AS tyres,
	sum(CASE WHEN "Item" = 'Saddles' THEN "Number of Items" ELSE 0 END) AS saddles,
	sum(CASE WHEN "Item" = 'Brakes' THEN "Number of Items" ELSE 0 END) AS brakes
FROM
	pd2021w31_data_for_pivot
WHERE "Status" <> 'Return to Manufacturer'
GROUP BY 1;


