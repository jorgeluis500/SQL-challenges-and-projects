-- Exploration

USE varied_tables;

SELECT * FROM sentences_table;

-- STEP 1
-- Create a scaffolding table (in this case I already know the max number of words in a sentence, which is 6)

CREATE TEMPORARY TABLE scaffolding (
One_number INT,
number_of_row INT)
;

INSERT INTO scaffolding (One_number, number_of_row)
VALUES 
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6)
;

ALTER TABLE scaffolding
DROP COLUMN	One_number;

SELECT 
*
FROM scaffolding
;

-- STEP 2
-- 1. Get the number of words in each sentence
-- 2. Get the max number of words in a sentence (for the scaffolding)
-- 3. Join the query with the scaffolding
-- 4. Limit the number of rows to the number of words in each sentence

-- Used nested queries for learning purposes. Better to use Windows functions

-- DROP TEMPORARY TABLE rows_multiplied;
CREATE TEMPORARY TABLE rows_multiplied
SELECT 
	*,
	length(Sentence) - LENGTH(Replace(Sentence,' ',''))+1 AS word_count -- number of words in each sentence
FROM sentences_table
CROSS JOIN -- 2b. to get the max number of words in the dataset
(
	SELECT 
	MAX(word_count) as Max_words -- 2a. get the max number of words from the dataset
		FROM (
			SELECT 
			*,
			length(Sentence) - LENGTH(Replace(Sentence,' ',''))+1 AS word_count-- 1. Get the number of words in each sentence
			FROM sentences_table
		) as all_text
	) as max_word
    
CROSS JOIN scaffolding -- 3. Join the query with the scaffolding
HAVING
	word_count >= number_of_row -- 4. Limit the number of rows to the number of words in each sentence
ORDER BY
Number
;

-- STEP 3
-- 3a. Test regex. Create the regex to extract words
-- 3b. Extract the words from each line, in sequence, with the newly created regex

-- 3a. Test regex. Create the regex to extract words
SELECT 
	regexp_substr("Let's addd another once",'(\\s?\\S+\\s){2}') AS words -- this gives me the {nth} group of (space word_any_character space)
;

-- 3b. Extract the words from each line, in sequence, with the newly created regex

WITH regex_test AS (
	SELECT 
	*,
	CONCAT('(\\s?\\S+\\s){',number_of_row,'}') AS regex_arg,
	regexp_substr(Sentence,CONCAT('(\\s?\\S+\\s?){',number_of_row,'}')) AS Sentence_gradual
	-- SUBSTRING_INDEX(Sentence, ' ',-2), -- to get the last word in the gradual sentence
    -- SUBSTRING_INDEX(Sentence, ' ',-1) -- to get the last word in the whole sentence
	FROM rows_multiplied
)
SELECT 
	*,
	CASE WHEN word_count <> number_of_row THEN SUBSTRING_INDEX(Sentence_gradual, ' ',-2) ELSE SUBSTRING_INDEX(Sentence_gradual, ' ',-1) END AS word_extracted
FROM regex_test
;

