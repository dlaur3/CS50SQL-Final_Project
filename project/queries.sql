/*
I elected to load a csv file to my database.
This file is structured as follows:
Top portion: tipical queries users would run
Bottom portion: queries used to build the db
*/

-- Typical quereis

-- SELECT the top 10 cities with the most fraudulant transactions
SELECT * FROM "fraud_by_city" LIMIT 10;

-- DELETE a fraudulant transaction from the fraud_transactions table

DELETE FROM "fraud_transactions"
WHERE "id" = 3;

-- ---------------------------------------------------------------------------------------------------------------------------------------------

-- General overview of the transactions_temp table
SELECT * FROM "transactions_temp" LIMIT 20;

-- Cleaning: Users will use these queries to clean the transaction_temp table

-- are there any duplicate records in the transactions temp table
SELECT "trans_date_trans_time", "merchant", "category", "amt", "city", "state", "lat", "long", "city_pop", "job", "dob", "trans_num", "merch_lat", "merch_long", "is_fraud", COUNT(*) AS "count"
FROM "transactions_temp"
GROUP BY "trans_date_trans_time", "merchant", "category", "amt", "city", "state", "lat", "long", "city_pop", "job", "dob", "trans_num", "merch_lat", "merch_long", "is_fraud"
HAVING "count" > 1;
--Yes

-- how many duplicate reords are there?

SELECT COUNT (*) AS "num_dups"
FROM (
    SELECT "trans_date_trans_time", "merchant", "category", "amt", "city", "state", "lat", "long", "city_pop", "job", "dob", "trans_num", "merch_lat", "merch_long", "is_fraud", COUNT(*) AS "count"
FROM "transactions_temp"
GROUP BY "trans_date_trans_time", "merchant", "category", "amt", "city", "state", "lat", "long", "city_pop", "job", "dob", "trans_num", "merch_lat", "merch_long", "is_fraud"
HAVING "count" > 1
) AS subquery;

-- delete the duplicate records

WITH CTE AS (
    SELECT *,
    ROW_NUMBER() OVER
    (PARTITION BY
    "trans_date_trans_time", "merchant", "category", "amt", "city", "state", "lat", "long", "city_pop", "job", "dob", "trans_num", "merch_lat", "merch_long", "is_fraud"
    ORDER BY "trans_num") AS rn
    FROM "transactions_temp"
)
DELETE FROM "transactions_temp"
WHERE "trans_num" IN (
    SELECT "trans_num"
    FROM CTE
    WHERE rn > 1
);
--With assistance from cs50 duck debugger, we were able ot remove duplicate records using a commmon table expression

-- Are there any duplicate transaction numbers?
SELECT "trans_num", COUNT("trans_num") AS "count"
FROM "transactions_temp"
GROUP BY "trans_num"
HAVING "count" > 1;
-- There is not!!!

-- is fraud should be either 1 or 0. Are there any records in is_fraud where the value is not 1 or 0?
SELECT *
FROM "transactions_temp"
WHERE "is_fraud" <> 1 AND "is_fraud" <> 0;

-- delete the rows returned by the above query
DELETE FROM "transactions_temp"
WHERE "is_fraud" <> 1 AND "is_fraud" <> 0;

/*Upon further inspection of the fraud_data.csv file, it seems like the trans_date_trans_time column is in the DD-MM-YYYY HH:MM format.
The query below will make every value in the trans_date_trans_time column in this format: YYYY-MM-DD HH:MM
*/
UPDATE "transactions_temp"
SET "trans_date_trans_time" = CASE
WHEN "trans_date_trans_time" LIKE '%-%-%' THEN
-- Convert DD-MM-YYYY HH:MM to YYYY-MM-DD HH:MM
SUBSTR("trans_date_trans_time", 7, 4) || '-' ||
SUBSTR("trans_date_trans_time", 4, 2) || '-' ||
SUBSTR("trans_date_trans_time", 1, 2) || ' ' ||
SUBSTR("trans_date_trans_time", 12, 5)
ELSE
"trans_date_trans_time"
END;

-- A user would write this query t change the format of the dob column from mm/dd/yyyy to YYYY-MM-DD

UPDATE "transactions_temp"
SET "dob" =
-- Convert MM/DD/YYYY to YYYY-MM-DD
SUBSTR("dob", 7, 4) || '-' ||
SUBSTR("dob", 1, 2) || '-' ||
SUBSTR("dob", 4, 2);

-- Return a distinct list of the "job" column
SELECT DISTINCT "job" FROM "transactions_temp" ORDER BY "job";

/*
reformat the values with this format: "y, x" to x y
to do this, we must use the TRIM(), SUBSTR() REPLACE() and INSTER() functions
The REPLACE Function will be used to remove the quotation marks
The INSTER() function can help us locate the ,
Using the SUBSTR() and INSTER() functions, we can change the order of the string
TRIM() will clean up any leading or trailing spaces
*/
-- remove quotation marks
UPDATE "transactions_temp"
SET "job" =
REPLACE("job", '"', '')
WHERE "job" LIKE '"%';

-- change order for columns containing commas
UPDATE "transanctions_temp"
SET "job" =
TRIM(SUBSTR("job", INSTR("job", ',') + 1)) || ' ' ||
TRIM(SUBSTR("job", 1, INSTR("job", ',') - 1 ))
WHERE "job" LIKE '%,%';

-- change all charactors to lowercase in the "job" column
UPDATE "transactions_temp"
SET "job" =
LOWER("job");

-- Replace the quotation marks in the merchants column
UPDATE "transaction_temp"
SET "merchant" = REPLACE("merchant", '"', '');

-- -----------------------------------------------------------------------------------------------------------------------------------------------

/*
Now that the "transaction_temp" table is clean, there seems to be redundancies.
A user could use the queries below to figure out how to normalize the transaction_temp table
*/
-- Does each city have a distinct latitude and longitude
SELECT "city", "state", COUNT(DISTINCT "lat") AS "count_lat", COUNT(DISTINCT "long") AS "count_long"
FROM "transactions_temp"
GROUP BY "city"
HAVING "count_lat" > 1 OR "count_long" > 1
ORDER BY "city";
--No

-- Does each merchant have a distinct lat_merch and long_merch
SELECT "merchant", COUNT(DISTINCT "merch_lat"), COUNT(DISTINCT "merch_long") AS "unq_loc"
FROM "transactions_temp"
GROUP BY "merchant"
HAVING "unq_loc" > 1;
-- No

-- can many locations have many merchants?
SELECT "lat", "long", COUNT(DISTINCT "merchant") AS "count_merch"
FROM "transactions_temp"
GROUP BY "lat", "long"
HAVING "count_merch" > 1;
-- Yes. This means there is a many to many relationship between merchants and cities

-- there are no duplicate transaction id's thus merchants and transactions have a one to many relationship
-- with the queries above, we can now make some tables to normalize the transaction_temp table

-- -----------------------------------------------------------------------------------------------------------------------------------------------

-- These queries would be used by the user to load the data from the transactions_temp table to the tables in the database

-- insert merchant from the transactions_temp table to the merchants table
INSERT INTO "merchants" ("name")
SELECT DISTINCT "merchant" FROM "transactions_temp";

-- insert city, state, lat, long, city_pop from transactions_temp to locations
INSERT INTO "locations" ("city", "state", "lat", "long", "city_pop")
SELECT DISTINCT"city", DISTINCT "state", DISTINCT "lat", DISTINCT "long", DISTINCT "city_pop" FROM "transactions_temp";

-- insert "merch_lat" and "merch_long" from transactions_temp to merch_locs
INSERT INTO "merch_locs" ("lat", "long")
SELECT DISTINCT "merch_lat", "merch_long" FROM "transactions_temp";

-- insert "merch_id" into the merch_locs table
UPDATE "merch_locs"
SET "merch_id" = "merchants"."id"
FROM "merchants"
JOIN "transactions_temp" ON "merchants"."name" = "transactions_temp"."merchant"
WHERE "merch_locs"."lat" = "transactions_temp"."merch_lat"
AND
"merch_locs"."long" = "transactions_temp"."merch_long";

-- insert trans_date_trans_time, category, amt, job, dob, is_fraud from the transactions_temp table to the transactions table

INSERT INTO "transactions" ("date_time", "merch_id", "category", "amount", "location_id", "job", "dob", "is_fraud")
SELECT
t."trans_date_trans_time",
m."id",
t."category",
t."amt",
l."id",
t."job",
t."dob",
t."is_fraud"
FROM "transactions_temp" t
JOIN "merchants" m ON t."merchant" = m."name"
JOIN "locations" l ON t."city" = l."city" AND t."state" = l."state" AND t."lat" = l."lat" AND t."long" = l."long"
ORDER BY t."trans_date_trans_time" ASC;

-- Now that all of the data is loaded to the db, we can drop the transactions_temp table
DROP TABLE "transactions_temp";

-- add a deleted column to the transactions table
ALTER TABLE "transactions"
ADD COLUMN "deleted" INTEGER DEFAULT 0;


-- create a trigger to soft delete transactions from the "fraud_transactions" view
CREATE TRIGGER "delete"
INSTEAD OF DELETE ON "fraud_transactions"
FOR EACH ROW
BEGIN
    UPDATE "transactions" SET "deleted" = 1
    WHERE "id" = OLD."id"
END;
