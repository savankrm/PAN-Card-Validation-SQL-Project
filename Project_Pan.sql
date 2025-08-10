DROP TABLE IF EXISTS PAN_DATA
--Creation of tables 
CREATE TABLE PAN_DATA (PAN_NUMBER TEXT)
--Data load 
SELECT
	*
FROM
	PAN_DATA
	--Data Cleaning and Preprocessing: 
	--1.Identify and Handle missing data 
SELECT
	*
FROM
	PAN_DATA
WHERE
	PAN_NUMBER IS NULL;

--2. Check for dupllicate pan numbers
SELECT
	PAN_NUMBER,
	COUNT(*)
FROM
	PAN_DATA
GROUP BY
	PAN_NUMBER
HAVING
	COUNT(*) > 1
	--3. Handling leading/tariling spaces 
SELECT
	*
FROM
	PAN_DATA
WHERE
	PAN_NUMBER != TRIM(PAN_NUMBER)
	--4. Correct letter case
SELECT
	*
FROM
	PAN_DATA
WHERE
	PAN_NUMBER != UPPER(PAN_NUMBER)
	--Combined data for validation after Data Cleaning and Preprocessing:
DROP TABLE IF EXISTS PAN_CHECK_DATA
CREATE TABLE PAN_CHECK_DATA AS
SELECT DISTINCT
	(UPPER(TRIM(PAN_NUMBER))) AS PAN_ID
FROM
	PAN_DATA
WHERE
	PAN_NUMBER IS NOT NULL
	AND TRIM(PAN_NUMBER) <> ''
SELECT
	*
FROM
	PAN_CHECK_DATA
	--Validation --Idea is to have a function for it 
CREATE OR REPLACE FUNCTION IS_VALID_PAN (PAN_ID TEXT) RETURNS BOOLEAN AS $$
DECLARE
    letter_part TEXT;
    digit_part TEXT;
    i INT;
    is_seq BOOLEAN := TRUE;
BEGIN
--Basic Format & Lenght check 
    IF pan_id !~ '^[A-Z]{5}[0-9]{4}[A-Z]$' THEN
        RETURN FALSE;
    END IF;
--extracting first 2 parts for further validation  
	letter_part := substring(pan_id from 1 for 5);
    digit_part := substring(pan_id from 6 for 4);


--Checking if first 5 letters of sequectal or adjacent are one same 

    FOR i IN 1..4 LOOP
        IF substring(letter_part, i, 1) = substring(letter_part, i + 1, 1) THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    is_seq := TRUE;
    FOR i IN 1..4 LOOP
        IF ascii(substring(letter_part, i + 1, 1)) != ascii(substring(letter_part, i, 1)) + 1 THEN
            is_seq := FALSE;
            EXIT; -- Not sequential, no need to check further
        END IF;
    END LOOP;
    IF is_seq THEN
        RETURN FALSE; -- letters are sequential (ABCDE etc.)
    END IF;

    -- Check adjacent same digits
    FOR i IN 1..3 LOOP
        IF substring(digit_part, i, 1) = substring(digit_part, i + 1, 1) THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    -- Check for sequential digits using loop
    is_seq := TRUE;
    FOR i IN 1..3 LOOP
        IF cast(substring(digit_part, i + 1, 1) AS INT) != cast(substring(digit_part, i, 1) AS INT) + 1 THEN
            is_seq := FALSE;
            EXIT;
        END IF;
    END LOOP;
    IF is_seq THEN
        RETURN FALSE; -- digits are sequential (1234 etc.)
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

---Getting Valid and Invalid Pans
SELECT
	PAN_ID,
	CASE
		WHEN IS_VALID_PAN (PAN_ID) = TRUE THEN 'Valid Pan'
		ELSE 'Invalid Pan'
	END
FROM
	PAN_CHECK_DATA
	----Summary Report
WITH
	VALIDATION_STATUS AS (
		SELECT
			PAN_ID,
			CASE
				WHEN IS_VALID_PAN (PAN_ID) = TRUE THEN 'Valid Pan'
				ELSE 'Invalid Pan'
			END AS STATUS
		FROM
			PAN_CHECK_DATA
	),
	COUNTS AS (
		SELECT
			(
				SELECT
					COUNT(*)
				FROM
					PAN_DATA
			) AS TOTAL_RECORDS_PROCESSED,
			(
				SELECT
					COUNT(*)
				FROM
					VALIDATION_STATUS
				WHERE
					STATUS = 'Valid Pan'
			) AS TOTAL_VALID_PANS,
			(
				SELECT
					COUNT(*)
				FROM
					VALIDATION_STATUS
				WHERE
					STATUS = 'Invalid Pan'
			) AS TOTAL_INVALID_PANS
	)
SELECT
	C.TOTAL_RECORDS_PROCESSED,
	C.TOTAL_VALID_PANS,
	C.TOTAL_INVALID_PANS,
	C.TOTAL_RECORDS_PROCESSED - (C.TOTAL_VALID_PANS + C.TOTAL_INVALID_PANS) AS MISSING_OR_UNPROCESSED
FROM
	COUNTS C;