# Design Document

By Dominic Laure

Video overview: https://youtu.be/GxmpmMnn_gY

## Scope

The database for credit card fraud includes entities to track trends in fraudulent credit card transactions. As such, included in the database's scope is:

* Merchants, including name and locations of the merchant
* Location, including basic identifying information
* Transactions, including date and time of the transactions, category of the transaction, amount of the transaction, job and date of birth of the buyer, and if the transaction was a case of fraud

Out of the scope are elements on identification of the credit card holder, and details that lead to the transaction being flaged as fraudulant.

## Functional Requirements

This database will support:

* Tracking the date, time, location, and merchant of fraudulant and non fraudulant transactions
* Merchants having multiple locations

Note that in this iteration, the system will not track a transaction with more than one location or merchant

## Representation

Entities are captured in SQLite tables with the following schema.

### Entities

The database includes the following entities:

#### Merchants

The `merchants` table includes:

* `id`, which specifies the unique ID for the merchant as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `name`, which specifies the merchant's name as `TEXT`, given `TEXT` is appropriate for name fields.

All columns in the `merchants` table are required, and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Merchant Location

The `merch_locs` table includes:

* `id`, which specifies the unique id for the merchant location as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `merch_id`, which is the ID of the merchant for the respective location represented as an `INTEGER`. This column thus has the `FOREIGN KEY` constraint applied, referencing the `id` column in the `merchants` table to ensure data integrety.
* `lat`, which is the latitude, relevent to the merchant. This column is represented with a `NUMERIC` type affinity, which can store either floats or integers.
* `long`, which is the longitude, relevent to the merchant. This column is represented with a `NUMERIC` type affinity, which can store either floats or integers.

All columns are required and hence have the `NOT NULL` constraint applied where a `PRIMARY KEY` or `FOREIGN KEY` constraint is not. No other constraints are necessary.

#### Locations

The `locations` table includes:

* `id`, which specifies the unique id for the location as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `city`, which specifies the city's name as `TEXT`, given `TEXT` is appropriate for name fields.
* `state`, which specifies the states name as `TEXT`, given `TEXT` is appropriate for name fields.
* `lat`, which is the latitude, relevent to the city and state. This column is represented with a `NUMERIC` type affinity, which can store either floats or integers.
* `long`, which is the longitude, relevent to the city and state. This column is represented with a `NUMERIC` type affinity, which can store either floats or integers.
* `city_pop`, which is the population of the respective location as an `INTEGER`.

All columns in the `merchants` table are required, and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Transactions

The `transactions` table incudes:

* `id`, which specifies the unique id for the location as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `date_time`, which specifies when the transaction occured. Timestamps in SQLite can be conveniently stored as `NUMERIC`, per SQLite documentation at <https://www.sqlite.org/datatype3.html>. The default value for the `date_time` attribute is the current timestamp, as denoted by `DEFAULT CURRENT_TIMESTAMP`
* `merch_id`, which is the ID of the merchant of the transaction represented as an `INTEGER`. This column thus has the `FOREIGN KEY` constraint applied, referencing the `id` column in the `merchants` table to ensure data integrety.
* `category`, which specifies the nature of the transaction as `TEXT`.
* `amount`, which specifies the dolor value of the transaction represented as `NUMERIC`.
* `location_id`, which is the ID of the location of the transaction represented as an `INTEGER`. This column thus has the `FOREIGN KEY` constraint applied, referencing the `id` column in the `locations` table to ensure data integrety.
* `job`, which specifies the profession of the buyer as`TEXT`.
* `dob`, which specifies the birthdate of the buyer as NUMERIC
* `is_fraud`, which specifies if the transaction was a case of fraud as an `INEGER`.

All columns are required and hence have the `NOT NULL` constraint applied where a `PRIMARY KEY` or `FOREIGN KEY` constraint is not. The `is_fraud` column has an additional constraint to check if its value is either 1 or 0, given thatthese are the only valid values in this column. The transaction's `date_time` attribute defaults to the current timestamp when a new row is inserted.

### Relationships

The below entity relationship diagram describes the relationships among the entities in the database.

![ER Diagram](fraud.db_entity_diagram.drawio.png)

As detailed by the diagram:

* A transaction is associated with one and only one location. At the same time, a location can have many transactions.
* A transaction is associated with one and only one merchant. At the same time, a merchant can have many transactions.
* A merchant's location can have one and only one merchant. At the same time, a merchant can have many merchant locations.

## Optimizations

It is common for users of the database to access all of the fraudulant transactions of a particular merchant. For that reason, an index was created on the `merch_id` and the `is_fraud` column to speed up the identification of merchants by those columns.

Similarly, it is also common for users of the database to access all of the fraudulant transactions of a particular location. For that reason, an index was created on the `location_id` and the `is_fraud` column to speed up the identification of location by those columns.

## Limitations

The current schema assumes one merchant per transaction. Multiple merchants for the same transaction would require a shift to a many-to-many relationship between merchants and transaction.
