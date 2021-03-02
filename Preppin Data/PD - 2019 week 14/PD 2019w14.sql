-- Preppin Data
-- 2019 Week 14
-- https://preppindata.blogspot.com/2019/04/2019-week-14.html

-- SQL flavor: T-SQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Use of variables

USE PreppinData;

-- Exploration and dataset enrichement

DECLARE @@Meal_Deal_Price INT = 5;
DECLARE @@NUllPrice DECIMAL(2,1) = 1.5;
DECLARE @@Meal_courses INT = 3;
DECLARE @@Ticket INT = 330826; -- for test purposes

-- SELECT * FROM #enriched  WHERE TicketID = @@Ticket;


DROP TABLE IF EXISTS #enriched;
SELECT 
	*,
	CASE WHEN MemberID IS NULL THEN 0 ELSE MemberID END AS new_member_id,
	ROW_NUMBER() OVER (PARTITION BY TicketID, Type ORDER BY TicketID, Type) AS number_of_item_per_type_in_ticket,
	COUNT(*) OVER (PARTITION BY TicketID, Type ORDER BY TicketID, Type) AS items_per_types_in_ticket,
	CASE WHEN Price IS NULL THEN @@NUllPrice ELSE Price END AS new_price,
	AVG(CASE WHEN Price IS NULL THEN @@NUllPrice ELSE Price END) OVER (PARTITION BY TicketID, Type ORDER BY TicketID, Type) AS avg_price_per_type
INTO #enriched
FROM dbo.pd2019w14_cafe_orders_by_product
;


-- STEP 2 
-- Calculate the aggregations


DROP TABLE IF EXISTS #aggregated
SELECT
	TicketID,
	COUNT(DISTINCT Type) AS types_in_ticket,
	MIN(items_per_types_in_ticket) AS min_items_per_type_per_ticket_aka_meal_deals,
	COUNT(*) AS items_in_ticket,
	SUM(new_price) AS Total_ticket_price,
	MIN(items_per_types_in_ticket) *@@Meal_Deal_Price AS Potential_Meal_Deals_Earnings
INTO #aggregated
FROM #enriched
GROUP BY
	TicketID
;

-- STEP 3
-- Join the #enriched and the #aggregations temp tables and create the new conditions

DROP TABLE IF EXISTS #all_data;
SELECT
    e.TicketID,
    e.Date,
    e.MemberID,
    e.[Desc],
    e.Price,
    e.Type,
    e.new_member_id,
	e.number_of_item_per_type_in_ticket,
    e.items_per_types_in_ticket,
    e.new_price,
    e.avg_price_per_type,
    a.types_in_ticket,
    a.min_items_per_type_per_ticket_aka_meal_deals,
    a.items_in_ticket,
	a.Total_ticket_price,
	a.Potential_Meal_Deals_Earnings,
	CASE WHEN a.types_in_ticket = @@Meal_courses THEN 1 ELSE 0 END AS is_meal_possible, -- The three types must be in a ticket to be a meal
	CASE WHEN a.types_in_ticket = @@Meal_courses AND e.number_of_item_per_type_in_ticket <= a.min_items_per_type_per_ticket_aka_meal_deals 
		THEN 1 
		ELSE 0 
		END AS is_item_in_meal, -- If the meal is possible AND the item rank in the ticket is less or equal to the number of possible meals, then the item should be in a meal
	CASE WHEN a.types_in_ticket = @@Meal_courses AND e.number_of_item_per_type_in_ticket > a.min_items_per_type_per_ticket_aka_meal_deals 
		THEN e.avg_price_per_type 
		ELSE 0 
		END AS Excess_price -- If the meal is possible AND the item rank in the ticket is greater than number of possible meals, then the item is in excess, so give me the price
INTO #all_data
FROM
    #enriched e
    LEFT JOIN #aggregated a
		ON e.TicketID = a.TicketID
-- ORDER BY e.TicketID, e.Type, e.number_of_item_per_type_in_ticket
;

-- STEP 4
-- Aggregate everything by ticket and calculate the variance

SELECT 
	FORMAT(AVG(Total_ticket_price), 'N2') AS Total_ticket_price,
	FORMAT(AVG(Total_ticket_price) - (AVG(Potential_Meal_Deals_Earnings) + SUM(Excess_price)), 'N2') AS Ticket_Price_Variance_to_Meal_Deal_Earnings,
	AVG(Potential_Meal_Deals_Earnings) AS Total_Meal_Deal_Earnings,
	FORMAT(SUM(Excess_price), 'N2') AS Total_Excess,
	TicketID,
	new_member_id AS MemberID
FROM #all_data
WHERE 
	is_meal_possible = 1 -- AND TicketID=  @@Ticket -- For test purposes
GROUP BY 
	TicketID,
	new_member_id
;