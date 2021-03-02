-- Preppin Data
-- 2019 Week 10
-- https://preppindata.blogspot.com/2019/04/2019-week-10.html

-- SQL flavor: MySQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regular Expressions

USE preppindata;

-- Exploration
SELECT * FROM `2019w10_mailing_list`;
SELECT * FROM `2019w10_unsuscribe_list`;
SELECT * FROM `2019w10_cust_lt_value`;

-- Step 1. Create the a common key in all datasets, so we can join them later
-- a) The common feature that can be assembled is the first letter of the firtname and the lastname, 
	-- all in lowercase and without the numbers of the email addresses. It will be called f_lastname
    -- However, at the end, there are four combinations of letters and numbers that mess it up https://preppindata.blogspot.com/2019/04/2019-week-10-solution.html
-- b) Dates need to be standarized in mailing list and unsuscribe list

CREATE TEMPORARY TABLE mailing_list_1 
	SELECT 
		*,
		REGEXP_REPLACE(LEFT(SUBSTRING_INDEX(email,'@',1), LENGTH(SUBSTRING_INDEX(email,'@',1))-1), '[0-9]','') AS f_lastname,
        str_to_date(Sign_up_Date,'%d/%m/%Y') AS Clean_Sign_up_Date
	FROM 2019w10_mailing_list
;

CREATE TEMPORARY TABLE unsuscribe_list_1 
	SELECT 
		*,
		REGEXP_REPLACE(CONCAT( LOWER(LEFT(first_name,1)), LOWER(Last_name)),'[[:space:]]|-','') AS f_lastname, -- There are one names with space and hypen in the middle of the last name
        str_to_date(Date,'%d.%m.%Y') AS Clean_unsuscribe_date
	FROM 2019w10_unsuscribe_list
;

CREATE TEMPORARY TABLE cust_lt_value_1 
	SELECT 
		*,
		REGEXP_REPLACE(LEFT(SUBSTRING_INDEX(email,'@',1), LENGTH(SUBSTRING_INDEX(email,'@',1))-1), '[0-9]','') AS f_lastname
	FROM 2019w10_cust_lt_value
;

-- Step 2: Join the mailing list with the unsuscriptions

-- DROP TEMPORARY TABLE new_mailing_list;
CREATE TEMPORARY TABLE new_mailing_list 
	SELECT
	    CASE 
			WHEN ml.Clean_Sign_up_Date > ul.Clean_unsuscribe_date THEN 'Resuscribed' 
            WHEN ul.Clean_unsuscribe_date IS NULL THEN 'Suscribed'
            ELSE 'Unsuscribed' END 
		AS Status,
        ml.email, 
		MAX(ml.Liquid) AS Interested_in_liquid, 
		MAX(ml.Bar) AS Interested_in_soap, 
		ml.Clean_Sign_up_Date,
		ul.Clean_unsuscribe_date,
		TIMESTAMPDIFF(MONTH, Clean_Sign_up_Date, Clean_unsuscribe_date) AS Months_before_Unsubscribed,	
        ml.f_lastname,
        cltv.`Liquid Sales to Date`, 
		cltv.`Bar Sales to Date`
	FROM mailing_list_1 ml
	LEFT JOIN unsuscribe_list_1 ul
		ON ml.f_lastname = ul.f_lastname
	LEFT JOIN cust_lt_value_1 cltv
		ON ml.f_lastname = cltv.f_lastname
	GROUP BY
		CASE 
			WHEN ml.Clean_Sign_up_Date > ul.Clean_unsuscribe_date THEN 'Resuscribed' 
            WHEN ul.Clean_unsuscribe_date IS NULL THEN 'Suscribed'
            ELSE 'Unsuscribed' END,
		ml.email, 
		ml.Clean_Sign_up_Date,
		ul.Clean_unsuscribe_date,
        ml.f_lastname,
        cltv.`Liquid Sales to Date`, 
		cltv.`Bar Sales to Date`
;
-- Test
select * from new_mailing_list; 

-- Finaly, for the Suscription table, select only those without unsuscribe dates and those that have resuscribed
-- Join it with the CLTV table

SELECT -- Months_before_Unsubscribed, to test
	Status,
	email, 
	Interested_in_liquid, 
	Interested_in_soap, 
	Clean_Sign_up_Date, 
	Clean_unsuscribe_date,
    `Liquid Sales to Date`, 
	`Bar Sales to Date`
FROM new_mailing_list
WHERE 
	Status IN ('Suscribed', 'Resuscribed' );

-- For the Mailing list Analytics table, groups certain metrics

SELECT 
	CASE 
		WHEN Months_before_Unsubscribed IS NULL THEN ''
        WHEN Months_before_Unsubscribed <0 THEN ''
		WHEN Months_before_Unsubscribed <3 THEN '0-3'
		WHEN Months_before_Unsubscribed <6 THEN '3-6'
		WHEN Months_before_Unsubscribed <12 THEN '6-12'
        WHEN Months_before_Unsubscribed <24 THEN '12-24'
		ELSE '24+'
	END AS Months_before_Unsubscribed_group,
    Status, 
	Interested_in_liquid, 
	Interested_in_soap, 
	COUNT(DISTINCT email) AS email,
	SUM(`Liquid Sales to Date`) AS Liquid_Sales_to_Date, 
	SUM(`Bar Sales to Date`) AS Bar_Sales_to_Date
FROM new_mailing_list
GROUP BY
	Status, 
	Interested_in_liquid, 
	Interested_in_soap,
	CASE 
		WHEN Months_before_Unsubscribed IS NULL THEN ''
        WHEN Months_before_Unsubscribed <0 THEN ''
		WHEN Months_before_Unsubscribed <3 THEN '0-3'
		WHEN Months_before_Unsubscribed <6 THEN '3-6'
		WHEN Months_before_Unsubscribed <12 THEN '6-12'
        WHEN Months_before_Unsubscribed <24 THEN '12-24'
		ELSE '24+'
	END

;