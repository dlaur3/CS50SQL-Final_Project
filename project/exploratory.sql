-- Queries used to figure out the nature of the dataset

CREATE INDEX "merch_id_fraud_index" ON "transactions" ("merch_id", "is_fraud");
