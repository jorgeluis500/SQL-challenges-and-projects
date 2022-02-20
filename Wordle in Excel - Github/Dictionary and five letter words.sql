-- WORDLE VALID WORDS

-- STEP 0
-- Download a MySQL datadump of a dictionary from https://sourceforge.net/projects/mysqlenglishdictionary/files/
-- Import the datadump

-- STEP 1
-- Calculate lenght of the words
-- Define wordle conditions
	-- Only words, no terms with special characters defined in the dictionary
	-- 5-letter words
	-- 4-letter words in plural (then nouns only) so, 5-letter words

DROP TABLE IF EXISTS 	t_conditions ;
CREATE TEMPORARY TABLE 	t_conditions AS
WITH step_one AS (
	SELECT
			word,
			wordtype,
			definition,
			CASE WHEN wordtype = '' THEN 'Other' ELSE wordtype END AS wordtype_all,
			LENGTH(word) AS word_len,
			CASE WHEN (LENGTH(word) = 4 AND wordtype = 'n.') OR LENGTH(word) = 5 THEN TRUE ELSE FALSE END AS wordle_condition, 
			word REGEXP '^[a-zA-Z]*$' AS is_word, 
			ROW_NUMBER() OVER () AS original_order,
			ROW_NUMBER() OVER (PARTITION BY word ORDER BY word) AS definition_number
		FROM
			entries
)
SELECT
	original_order,
	word,
	CASE WHEN word_len = 4 AND wordtype = 'n.' THEN concat(word, 's') ELSE word END AS wordle_words,
-- 	wordtype,
	CAST(definition_number AS nchar) AS defstring,
	wordtype_all,
	definition,
	word_len AS original_word_len,
	wordle_condition,
	is_word
FROM
	step_one
;

SELECT * FROM t_conditions 
WHERE
	wordle_condition = 1
	AND is_word = 1
ORDER BY original_order -- Test
	;

-- STEP 2
-- Leave only Wordle conditions and group them to have unique values
-- Sort by original ORDER

SELECT
	wordle_words
-- 	, count(*) AS number_of_definitions
-- 	, group_concat(defstring, '_ ', 'Type: ',  wordtype_all, ' Def: ', definition, ' ') AS all_definitions
FROM
	t_conditions
WHERE
	wordle_condition = 1
	AND is_word = 1
GROUP BY 1
ORDER BY
	original_order
;