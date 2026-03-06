/*
In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc.
statements that compose it
*/

-- Represent merchant of transaction
CREATE TABLE "merchants" (
    "id" INTEGER,
    "name" TEXT NOT NULL UNIQUE,
    PRIMARY KEY("id")
);

-- Represent location of transaction
CREATE TABLE "locations" (
    "id" INTEGER,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "lat" NUMERIC NOT NULL,
    "long" NUMERIC NOT NULL,
    "city_pop" INTEGER,
    PRIMARY KEY("id")
);

-- Represent locations of the merchant
CREATE TABLE "merch_locs" (
    "id" INTEGER,
    "merch_id" INTEGER,
    "lat" NUMERIC NOT NULL,
    "long" NUMERIC NOT NULL,
    PRIMARY KEY("id"),
    FOREIGN KEY("merch_id") REFERENCES "merchants"("id")
);

-- Represent the transaction
CREATE TABLE "transactions" (
    "id" INTEGER,
    "date_time" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "merch_id" INTEGER,
    "category" INTEGER NOT NULL,
    "amount" NUMERIC NOT NULL CHECK(amount != 0),
    "location_id" INTEGER,
    "job" TEXT NOT NULL,
    "dob" NUMERIC NOT NULL,
    "is_fraud" INTEGER  NOT NULL CHECK("is_fraud" IN (0, 1)),
    "deleted" INTEGER NOT NULL DEFAULT 0 CHECK("deleted" IN(0,1)),
    PRIMARY KEY("id"),
    FOREIGN KEY("merch_id") REFERENCES "merchants"("id"),
    FOREIGN KEY("location_id") REFERENCES "locations"("id")
);

-- View of locations and the number of fraudulant transactions that have occured
CREATE VIEW "fraud_by_city" AS
SELECT l."city", l."state", SUM(t."is_fraud") AS "fraud_trans"
FROM "transactions" t
JOIN "locations" l ON t."location_id" = l."id"
GROUP BY l."city"
ORDER BY "fraud_trans" DESC;

-- Create a view of fraudulant transactions
CREATE VIEW "fraud_transactions" AS
SELECT "id", "date_time", "merch_id", "category", "amaount", "location_id", "job", "dob"
FROM "transactions"
WHERE "is_fraud" = 1;

-- create index on location_id and is_fraud in the transactions table
CREATE INDEX "loc_id_fraud_index" ON "transactions" ("location_id", "is_fraud");

-- create index on merch_id and is_fraud in the transactions table
CREATE INDEX "merch_id_fraud_index" ON "transactions" ("merch_id", "is_fraud");
