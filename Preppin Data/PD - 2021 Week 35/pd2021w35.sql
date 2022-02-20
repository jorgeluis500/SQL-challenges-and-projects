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
-- Split Widths & Lengths for pictures

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

-- Split Widths & Lengths for frames
-- Convert them to cm

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
, numbers AS (
	SELECT 
		*,
		CAST( (regexp_matches(frame_length,'(\d+)'))[1] AS INT) AS frame_length_number,
		CAST( (regexp_matches(frame_width,'(\d+)'))[1] AS INT) AS frame_width_number
	FROM frames_split
)
SELECT
	*,
	frame_length_number * (CASE WHEN regexp_match("Size", 'cm') = '{cm}' THEN 1 ELSE 2.54 END ) AS frame_length_number_cm,
	frame_width_number * (CASE WHEN regexp_match("Size", 'cm') = '{cm}' THEN 1 ELSE 2.54 END ) AS frame_width_number_cm
FROM numbers
;
	;

