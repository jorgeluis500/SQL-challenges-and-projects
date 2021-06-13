-- Preppin Data
-- 2021 Week 22
-- https://preppindata.blogspot.com/2021/06/2021-week-22-answer-smash.html

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Split strings
-- Get substring from strings
-- Check position of substring in strings with POSITION


-- STEP 1
-- The category dataset requires some cleaning so that Category and Answer are 2 separate fields 

DROP TABLE IF EXISTS t_new_cat;
CREATE TEMPORARY TABLE t_new_cat AS 
SELECT
    category_answer,
    split_part(category_answer, ': ', 1) AS category,
    trim(split_part(category_answer, ': ', 2)) AS answer 
FROM
    pd2021w22_categories
;
--SELECT * FROM t_new_cat; -- Test 

-- STEP 2
-- Join questions and answers

DROP TABLE IF EXISTS t_q_a;
CREATE TEMPORARY TABLE t_q_a AS 
SELECT
    q.q_no
    , q.category
    , q.question
    , a.answer_smash
FROM
    public.pd2021w22_questions q
INNER JOIN pd2021w22_answers a
  ON q.q_no = a.q_no
;
--SELECT * FROM t_q_a; -- Test

-- STEP 3
-- Join answers and names

DROP TABLE IF EXISTS t_names_answers;
CREATE TEMPORARY TABLE t_names_answers AS 
WITH ans_names AS (
    SELECT 
        a.q_no
        , a.answer_smash
        , n.names
        , SUBSTRING ( answer_smash from names ) as name_match
    FROM
        public.pd2021w22_answers  a
    INNER JOIN public.pd2021w22_names n
      ON TRUE
)
SELECT 
  q_no, 
  names,
  answer_smash
FROM ans_names
WHERE name_match is not null
;
--SELECT * FROM t_names_answers; -- Test

-- STEP 4 
-- Join questions, answers and names for the final answer

WITH final_query AS (
		SELECT
			qa.q_no,
			qa.question,
			nc.answer,
			na.names,
			na.answer_smash,
			POSITION( lower(nc.answer) IN lower(na.answer_smash)) as real_answer
		FROM t_q_a qa
		INNER JOIN t_names_answers na
			ON qa.answer_smash = na.answer_smash
		INNER JOIN t_new_cat nc
			ON qa.category = nc.category
)
SELECT
	q_no,
	question,
	answer,
	names,
	answer_smash
FROM final_query 
WHERE 
	real_answer <> 0
;