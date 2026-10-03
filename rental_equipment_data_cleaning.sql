/** DATA CLEANING equipment_rentals table **/

/* Step 1: Look for any NULLS or odd rows in each column, look at number of rows 
		Confirmed there are no NULLS 
		- rental_date 12 rows
		- rental_id 13937 rows PRIMARY KEY
		- asset_id 3903 rows 
		- market_id 10 rows 
		- rental_revenue 15384 rows 
		*/
SELECT DISTINCT rental_date FROM equipment_rentals ORDER BY rental_date DESC; -- date aggregated monthly 2017-01-01 ~ 2017-12-01
SELECT DISTINCT rental_id FROM equipment_rentals ORDER BY rental_id DESC; -- 4 digit id 
SELECT DISTINCT asset_id FROM equipment_rentals ORDER BY asset_id DESC; --3 to 4 digit id
SELECT DISTINCT market_id FROM equipment_rentals ORDER BY market_id DESC; -- id ranges from 1~9, 7329, 7522
SELECT DISTINCT rental_revenue FROM equipment_rentals ORDER BY rental_revenue DESC; -- ranges from 0 ~ 69.11

/* Step 2: Check for duplicate rows 
		Confirmed there are no duplicate rows */
WITH duplicate_rows AS(
SELECT *
	,ROW_NUMBER() OVER (PARTITION BY rental_date, rental_id, asset_id, market_id, rental_revenue) AS row_num
FROM equipment_rentals
)

SELECT 
	*
FROM duplicate_rows
WHERE row_num > 1;


/** DATA CLEANING equipment_asset_oec **/

/* Step 1: Look for any NULLS or odd rows in each column, look at number of rows 
		asset_id 3904 rows. NULL count 1024 rows. PRIMARY KEY (needs to be unique and non-null)
		market_id 25 rows. NULL count 1024 rows. has 14 more market_id than equipment_rentals table
		acqusition_date 20 rows. NULL count 1024 rows Date ranges from 2016-01-01, skips 2016 feb~may, 2016-06-01 ~ 2017-12-01
		equipment_class 3 rows. NULL count 21 rows
		oec has 1078 rows. NULL count 1024		*/
SELECT DISTINCT asset_id FROM equipment_asset_oec ORDER BY asset_id DESC;
SELECT DISTINCT market_id FROM equipment_asset_oec ORDER BY market_id DESC;
SELECT DISTINCT acquisition_date FROM equipment_asset_oec ORDER BY acquisition_date DESC;
SELECT DISTINCT equipment_class FROM equipment_asset_oec ORDER BY equipment_class DESC;
SELECT DISTINCT oec FROM equipment_asset_oec ORDER BY oec DESC;

SELECT asset_id FROM equipment_asset_oec WHERE asset_id IS NULL ORDER BY 1 DESC;
SELECT market_id FROM equipment_asset_oec WHERE market_id IS NULL ORDER BY 1 DESC;
SELECT acquisition_date FROM equipment_asset_oec WHERE acquisition_date IS NULL ORDER BY 1 DESC;
SELECT equipment_class FROM equipment_asset_oec WHERE equipment_class IS NULL ORDER BY 1 DESC;
SELECT oec FROM equipment_asset_oec WHERE oec IS NULL ORDER BY 1 DESC;

/* Step 2: Check for duplicate rows 
		2843 duplicate rows with multiple asset_id */
WITH duplicate_rows AS(
	SELECT 
		*
		,ROW_NUMBER() OVER (PARTITION BY asset_id) as row_num --partition by the specific columns that define what a "duplicate" means in business logic. asset_id is a primary key. Only 1 unique asset can be bought per market.
	FROM equipment_asset_oec
)

SELECT *
FROM duplicate_rows
WHERE row_num > 1;

/* Step 3: Create temp table before making any changes to tables & remove duplicate rows*/
DROP TABLE IF EXISTS temp_equipment_asset_oec;
CREATE TABLE temp_equipment_asset_oec AS
SELECT * FROM equipment_asset_oec;

/* Step 4: Delete asset_id duplicate rows */
WITH duplicate_rows AS(
	SELECT 
		*
		,ROW_NUMBER() OVER (PARTITION BY asset_id) as row_num --partition by the specific columns that define what a "duplicate" means in business logic. asset_id is a primary key. Only 1 unique asset can be bought per market.
	FROM temp_equipment_asset_oec
)

DELETE FROM temp_equipment_asset_oec
WHERE asset_id IN ( 
	SELECT asset_id 
	FROM (
		SELECT
		asset_id
		,ROW_NUMBER() OVER (PARTITION BY asset_id) as row_num 
		FROM temp_equipment_asset_oec
	) t
	WHERE row_num > 1
);

/* Step 5: Check if asset_id duplicate rows are gone */
WITH duplicate_rows AS(
	SELECT 
		*
		,ROW_NUMBER() OVER (PARTITION BY asset_id) as row_num --partition by the specific columns that define what a "duplicate" means in business logic. asset_id is a primary key. Only 1 unique asset can be bought per market.
	FROM temp_equipment_asset_oec
)

SELECT *
FROM duplicate_rows
WHERE row_num > 1;

/* Step 6: Remove the NULLs */
DELETE FROM temp_equipment_asset_oec
WHERE asset_id IS NULL 
	OR market_id IS NULL
	OR acquisition_date IS NULL
	OR equipment_class IS NULL
	OR oec IS NULL;

/* Step 7: Check if NULLs removed in temp table */
SELECT * FROM temp_equipment_asset_oec
WHERE asset_id IS NULL 
	OR market_id IS NULL
	OR acquisition_date IS NULL
	OR equipment_class IS NULL
	OR oec IS NULL;

/* Step 8: Remove contents inside equipment_asset_oec and replace with cleaned temp table contents */
BEGIN;

TRUNCATE TABLE equipment_asset_oec; --remove data from equipment_asset_oec table

INSERT INTO equipment_asset_oec 
SELECT asset_id, market_id, acquisition_date, equipment_class, oec FROM temp_equipment_asset_oec;

SELECT * FROM equipment_asset_oec ORDER BY asset_id, market_id; --check if all duplicates and nulls removed

COMMIT; --rollback if there is a mistake or commit if cleaning done


/** DATA CLEANING equipment_market_mapping **/

/* Step 1: Look for any NULLS or odd rows in each column, look at number of rows  
		- NULL row count 1
		- 10 unique market_id
		- market_open_date ranges from 2016-01-01 ~ 2017-09-01
*/
SELECT DISTINCT * FROM equipment_market_mapping ORDER BY market_id;

/* Step 2: Create temp table before making any changes to tables & remove duplicate rows*/
DROP TABLE IF EXISTS temp_equipment_market_mapping;
CREATE TABLE temp_equipment_market_mapping AS
SELECT DISTINCT * FROM equipment_market_mapping;

/* Step 3: Remove NULLs */
DELETE FROM temp_equipment_market_mapping
WHERE market_id IS NULL
	OR market_name IS NULL
	OR market_open_date IS NULL;

/* Step 4: Replace contents inside equipment_market_mapping with temp_equipment_market_mapping */
BEGIN;

TRUNCATE TABLE equipment_market_mapping;

INSERT INTO equipment_market_mapping
SELECT market_id, market_name, market_open_date FROM temp_equipment_market_mapping;
