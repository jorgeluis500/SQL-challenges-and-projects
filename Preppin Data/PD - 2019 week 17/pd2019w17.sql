-- Preppin Data
-- 2019 Week 17
-- Complicated since the process takes one or another route depending on the results
-- SQL Server used


-- SELECT * FROM pd2019w17_Voting_Systems; -- Exploration

-- Pre-processing
-- Create general table where Candidates are split and votes are counted

DROP TABLE IF EXISTS Split_letters
SELECT 
        *,
        LEFT(Voting_Preferences,1) AS first_letter,
        SUBSTRING(Voting_Preferences,2,1) AS second_letter,
        RIGHT(Voting_Preferences,1) AS last_letter,
        COUNT(*) OVER() AS total_votes
INTO    Split_letters
FROM    pd2019w17_Voting_Systems
;
-- SELECT * FROM Split_letters; -- Test

-- FIRST PAST THE POST SYSTEM
-- Group by the first letter and leave the candidate with maximun of votes

DROP TABLE IF EXISTS FPTP_final
SELECT 
        'FPTP' AS Voting_system,
        first_letter AS Winner 
        -- , COUNT(*) AS Votes
INTO FPTP_final
FROM    Split_letters
GROUP BY first_letter
ORDER BY COUNT(*) DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
;
-- SELECT * FROM FPTP_final; -- Test

-- AV ALTERNATIVE VOTE SYSTEM -- FIRST ATTEMPT
-- STEP 1
-- Count the votes and the first option percent

DROP TABLE IF EXISTS AV_1
SELECT 
        *,
        COUNT(*) OVER(PARTITION BY first_letter) AS First_letter_votes,
        COUNT(*) OVER(PARTITION BY first_letter) *100.0 / COUNT(*) OVER() AS First_option_percent
INTO    AV_1
FROM    Split_letters
;
-- SELECT * FROM AV_1; -- Test

-- STEP 2
-- Create the ranks

DROP TABLE IF EXISTS AV_2
SELECT 
        *,
        MIN(First_letter_votes) OVER () AS First_letter_vote_minimum,
        DENSE_RANK() OVER ( ORDER BY First_option_percent DESC) AS first_letter_rank_desc,
        DENSE_RANK() OVER ( ORDER BY First_option_percent ASC) AS first_letter_rank_asc,
        CASE WHEN First_option_percent > 50 THEN 1 ELSE 0 END AS is_there_a_winner
INTO    AV_2
FROM    AV_1
;
-- SELECT * FROM AV_2; -- Test

-- STEP 3 
-- Is there a winner?
-- Manual verification (not elegant). 
SELECT * FROM AV_2
WHERE is_there_a_winner =1
;
-- Empty set, there is not a winner, 

-- STEP 4
-- Second round. Eliminate the candidate with the lowest score

DROP TABLE IF EXISTS AV_3
SELECT 
        CASE WHEN First_letter_votes = First_letter_vote_minimum THEN second_letter ELSE first_letter END AS New_first_letter, 
        COUNT(*) OVER () AS total_votes_2 
INTO    AV_3
FROM    AV_2
;
-- SELECT * FROM AV_3; -- Test

-- STEP 5
-- Group and calculate the percentages

DROP TABLE IF EXISTS AV_4
SELECT 
        New_first_letter,
        COUNT(*) AS votes,
        COUNT(*) *100.0 /AVG(total_votes_2) AS percent_round_2
INTO AV_4
FROM    AV_3
GROUP BY New_first_letter
    ;

-- SELECT * FROM AV_4; -- Test

-- STEP 6
DROP TABLE IF EXISTS AV_5
SELECT 
    *,
     CASE WHEN percent_round_2 > 50 THEN 1 ELSE 0 END AS is_there_a_winner   
INTO AV_5
FROM AV_4;

-- SELECT * FROM AV_5; -- Test

DROP TABLE IF EXISTS AV_final
SELECT 
    'AV' AS Voting_System,
    New_first_letter AS Winner 
INTO AV_final
FROM AV_5
WHERE 
    is_there_a_winner =1
;
-- SELECT * FROM AV_final; -- Test


-- BORDA VOTING SYSTEM
-- STEP 1 
-- Assign the points to the candidates

DROP TABLE IF EXISTS Borda_1
SELECT 
    CONCAT(first_letter,'-3') AS First_points,
    CONCAT(second_letter,'-2') AS Second_points,
    CONCAT(last_letter,'-1') AS Third_Points
INTO Borda_1
FROM Split_letters
;

-- SELECT * FROM Borda_1; -- Test

-- STEP 2
-- Unpivot and split the candidates from their points

DROP TABLE IF EXISTS Borda_2
SELECT 
LEFT(Candidate_points,1) AS Candidate,
CAST( RIGHT(Candidate_points,1) AS INT) AS Points
INTO Borda_2
FROM (
        SELECT
            First_points AS Candidate_points
        FROM Borda_1
    UNION ALL
        SELECT
            Second_points
        FROM Borda_1
    UNION ALL
        SELECT
            Third_Points
        FROM Borda_1
) AS all_union
;
-- SELECT * FROM Borda_2; -- Test

-- Step 3 
-- Group by points and declare winner

DROP TABLE IF EXISTS Borda_final
SELECT
        'Borda' AS Voting_System,
        Candidate AS Winner
    --  , SUM(Points) AS Points
INTO    Borda_final
FROM    Borda_2
GROUP BY Candidate
ORDER BY SUM(Points) DESC
OFFSET 0 ROW FETCH NEXT 1 ROW ONLY
;

-- SELECT * FROM Borda_final; -- Test

-- FINAL RESULT

SELECT * FROM FPTP_final 
UNION ALL
SELECT * FROM AV_final
UNION ALL
SELECT * FROM Borda_final 





/* -- AV ALTERNATIVE VOTE - Another approach, imcomplete

WITH AV_1_1 AS (
    SELECT 
        sl.first_letter,
        COUNT(*) AS first_letter_votes,
        AVG(tt.Total_votes) AS total_votes,
        COUNT(*) * 1.0 / AVG(tt.Total_votes) AS first_letter_pct
        FROM Split_letters sl
    INNER JOIN
        (
        SELECT 
            COUNT(*) AS Total_votes
        FROM Split_letters
        -- WHERE first_letter <> 'B'
        ) AS tt -- total_table
    ON 1=1
    -- WHERE sl.first_letter <> 'B'
    GROUP BY first_letter
)

-- SELECT * FROM AV_1_1; -- Test

, AV_2_2 AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY first_letter_pct ASC ) AS rank_asc,
        DENSE_RANK() OVER (ORDER BY first_letter_pct DESC) AS rank_desc
    FROM AV_1_1
)

SELECT 
* 
FROM AV_2_2
;
 */

