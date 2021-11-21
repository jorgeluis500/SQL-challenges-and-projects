-- Preppin Data
-- 2021 Week 35
-- 

-- SQL flavor: PostgreSQL

-- TECHNIQUES LEARNED, FUNCTIONS USED, ETC.
-- Regular expresions (regex) to extract and transform strings

-- STEP 0 
-- Exploration
/*
SELECT "Size"
FROM pd2021w35_frames_csv;

SELECT "Picture", "Size"
FROM pd2021w35_pictures_csv;
*/

-- STEP 1
-- Split Widths & Lengths

-- For pictures

WITH pictures_splits AS (
	SELECT
		"Picture",
		"Size",
		CASE 
			WHEN "Size" LIKE '%cm2' THEN regexp_replace("Size", 'cm2', '') 
			ELSE split_part("Size", ' x ', 1) 
		END AS picture_lenght,
		CASE 
			WHEN "Size" LIKE '%cm2' THEN regexp_replace("Size", 'cm2', '') 
			ELSE split_part("Size", ' x ', 2)
		END AS picture_width
	FROM
		pd2021w35_pictures_csv
)
SELECT 
	"Picture",
	regexp_replace(picture_lenght, 'cm', '') AS picture_length,
	regexp_replace(picture_width, 'cm', '') AS picture_width
FROM pictures_splits
;

-- For frames

WITH frames_split AS (
	SELECT
		"Size",
		CASE 
			WHEN "Size" LIKE '%cm2' THEN regexp_replace("Size", 'cm2', '') 
			ELSE split_part("Size", ' x ', 1) 
		END AS frame_length,
		CASE 
			WHEN "Size" LIKE '%cm2' THEN regexp_replace("Size", 'cm2', '') 
			ELSE split_part("Size", ' x ', 2) 
		END AS frame_width
	FROM
		pd2021w35_frames_csv
)
SELECT 
*,
(regexp_matches(frame_length,'(\d+)'))[1] AS frame_length_number ,
(regexp_matches(frame_width,'(\d+)'))[1] AS frame_width_number
FROM frames_split
;

