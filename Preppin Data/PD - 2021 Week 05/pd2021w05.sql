-- Preppin Data
-- 2021 Week 5
-- https://preppindata.blogspot.com/2021/02/2021-week-5-dealing-with-duplication.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
--Joins

-- Groupings version of the solution

-- STEP 1
-- Group to see who attended which training

DROP TABLE IF EXISTS 	t_trainings ;
CREATE TEMPORARY TABLE 	t_trainings AS
SELECT
	training,
	"Contact Email",
	"Contact Name",
	client
FROM
	public.pd2021w05_joined_dataset_csv
GROUP BY
1, 2, 3, 4
;
--SELECT * FROM t_trainings; -- Test

-- STEP 2
-- Use an Aggregate step to group by Client, Client ID, Account Manager, and From Date.

DROP TABLE IF EXISTS 	t_acc_mans ;
CREATE TEMPORARY TABLE 	t_acc_mans AS
SELECT
	client,
	"Client ID",
	"Account Manager",
	"From Date",
	count(*) AS records
FROM
	public.pd2021w05_joined_dataset_csv
GROUP BY
1, 2, 3, 4
;

-- STEP 3
-- Next, use a further Summarize step to group by Client and get the Max From Date.

DROP TABLE IF EXISTS 	t_max_dates ;
CREATE TEMPORARY TABLE 	t_max_dates AS
SELECT
	client,
	max("From Date") AS max_date
FROM t_acc_mans
GROUP BY 1
;

-- STEP 4
-- Finally, use a Join step to join the results of these two Aggregates together on Client = Client and From Date = From Date. 
-- This gives us a nice, clean, up-to-date list of the current Account Managers and Client IDs for each Client.

DROP TABLE IF EXISTS 	t_client_man_max_date ;
CREATE TEMPORARY TABLE 	t_client_man_max_date AS
SELECT
	am.client,
	am."Client ID",
	am."Account Manager",
	md.max_date
FROM
	t_acc_mans am
INNER JOIN t_max_dates md
	ON am.client = md.client AND am."From Date" = md.max_date
;

-- Join back with the trainings dataset
SELECT
	t.training,
	t."Contact Email",
	t."Contact Name",
	t.client,
	cm."Client ID",
	cm."Account Manager",
	cm.max_date AS from_date
FROM
	t_trainings t
INNER JOIN t_client_man_max_date cm
ON
	t.client = cm.client
;