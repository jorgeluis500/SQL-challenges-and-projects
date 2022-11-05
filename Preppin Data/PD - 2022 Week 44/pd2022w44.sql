-- Preppin Data
-- 2022 Week 43
-- https://preppindata.blogspot.com/2022/11/2022-week-44-creating-order-ids.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Get initials from a name with string functions
-- Pad string with leading zeros with to_char
-- COALESCE

-- STEP 1
-- Create the unique date, extract the initials and pad the order nummber

WITH t_parsing AS (
	SELECT
		"Order Number",
		customer,
		"Order Date",
		"Date of Order",
		"Purchase Date",
		COALESCE("Order Date",	"Date of Order",	"Purchase Date") AS assembled_order_date,
		LEFT(customer,1) || SUBSTRING (customer, POSITION(' ' IN customer)+1,1) AS initials,
		to_char("Order Number", 'fm000000') AS padded 
	FROM
		public.pd2022w44_input
)
--STEP 2
-- Assemble the final dataset
SELECT
	initials || padded AS order_id,
	"Order Number",
	customer,
	assembled_order_date AS order_date
FROM
	t_parsing
;
