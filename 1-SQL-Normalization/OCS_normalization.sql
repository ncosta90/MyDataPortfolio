/*
				-- ONLINE CLOTHING STORE - OCS --
				-- NORMALIZATION PROJECT --

WE HAVE BEEN TASKED TO INVESTIGATE THE CURRENT DISING OF THE DATABASE.
IF THE CURRENT DESIGN IS INEFFICIENT WE NEED TO REDISING IT.

WE RECEIVE A PART OF THE CURRENT DATABASE THAT REPRESENTS THE SELLS (TRANSACTIONS) OF THE LAST 3 DAYS.

IT INCLUDES ONLY 1 TABLE, WITH SALES, CUSTOMERS AND PRODUCT DETAILS.

*/

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- PART 1: CREATING TABLE AND IMPORTING DATA --

-- 1.1) CREATING TABLE WHERE WE WILL STORAGE THE DATA FROM CSV.

CREATE TABLE transactions (
transactionid varchar,
timestampsec timestamp,
customerid varchar,
customername varchar,
shipping_state varchar,
item varchar,
description varchar,
retail_price float(2),
loyalty_discount float(2)
);

-- 1.2) IMPORTING CSV DATA INTO THE NEW TABLE.

COPY transactions
FROM '/Users/Shared/OCS_database_example.csv'
DELIMITER ','
CSV HEADER;

-- 1.3) CHECKING IF ALL RECORDS WERE SUCCESSFULLY IMPORTED.

SELECT * FROM transactions

-- 1.4) CONTROL OF HOW MANY RECORDS WERE IMPORTED, JUST TO DOUBLE CHECK IF WE HAVE ALL THE 3455 RECORDS FROM CSV.

SELECT COUNT(*)
FROM 
(
	SELECT DISTINCT *
	FROM transactions

) AS TMP -- 3455 RECORDS - CHECKED! -- AND NOT DUPLICATED ROWS.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

/*
-- PART 2: IS THE TABLE IN FIRST NORMAL FORM (1NF)? --

CONDITION A) DOES THE TABLE INCLUDES CELLS WITH MORE THAN ONE VALUE INSIDE? --> YES, IT DOES --> customername COLUMN.
CONDITION B) IS THERE ANY DUPLICATED ROW? --> NO, CONFIRMED IN POINT 1.4.
*/

-- 2.1) SPLITTING customername COLUMN INTO 2, ONE FOR customer_name AND OTHER FOR customer_surname.

ALTER TABLE transactions
ADD COLUMN customer_name varchar(20),
ADD COLUMN customer_surname varchar(20);

UPDATE transactions
SET customer_name = TRIM(SPLIT_PART(customername,' ',1))

UPDATE transactions
SET customer_surname = TRIM(SPLIT_PART(customername,' ',2))

ALTER TABLE transactions
DROP COLUMN customername;

SELECT * FROM transactions

-- 2.2) CONDITIONS 1 AND 2 CHECKED! --> 1NF CONFIRMED.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

/*
-- PART 3: IS THE TABLE IN SECOND NORMAL FORM? (2NF)?

CONDITION A) IS THE TABLE IN THE 1st NORMAL FORM? --> CONFIRMED.
CONDITION B) EVERY NON PRIME ATTRIBUTE OF THE TABLE DEPENDS ON THE WHOLE OF EVERY CANDIDATE KEY --> LETS CHECK IT:

CANDIDATE_KEYS --> THE PROPOSE OF THE TABLE IS ABOUT TO DOCUMENT EACH TRANSACTION --> EVERY SINGLE TRANSACTION MUST BE UNIQUE.
*/

/*
LETS CREATE A LIST OF POSSIBLE CANDIDATE_KEYS:

	- Transactionid: IT IS A CANDIDATE KEY -- OK!
	- Timestamp of the transaction: NO, BECAUSE THERE IS THE POSSIBILITY OF HAVING 2 TRANSACTIONS AT THE SAME TIME.
	- Timestamp + item_id: NO, WE BECAUSE THERE IS THE POSSIBILITY OF HAVING 2 DIFFERENT CUSTOMER BUYING THE SAME ITEM AT THE SAME TIME.
	- Timestamp + customer_id: IT IS ALMOST IMPOSIBLE TO HAVE THE SAME CUSTOMER BUYING SOMETHING AT EXACTLY THE SAME TIME, AT LEAST WE ARE DEALING WITH BUYING ROBOTS.
							   FOR THIS PROJECT WE WILL ASSUME THAT IT IS NOT POSSIBLE AND THIS IS A VALIDE CANDIDATE KEY.

PRIME ATTRIBUTES: ATTRIBUTES THAT ARE PART AT LEAST OF ONE CANDIDATE KEY --> WE HAVE 3: transactionid, timestampsec and customerid.
*/


--3.1) NOW WE CAN ANSWER THE QUESTION ABOUT EVERY NON PRIME ATTRIBUTE OF THE TABLE DEPENDING ON THE WHOLE OF EVERY CANDIDATE KEY --> AND THE ANSWER IS NO.

	--NO, FOR EXAMPLE customer_name DOES NOT DEPENDS ON THE WHOLE OF THE CANDIDATE KEY timestampsec + customerid, JUST KNOWING THE customerid IS ENOUGHT TO IDENTIFY THE customer_name.
	--SAME FOR shipping_state, loyalty_discount and customer_surname.
	
	--IN ORDER TO COMPLETE THE 2NF WE NEED TO CREATE A NEW SEPARATE TABLE FOR CUSTOMERS AND DELETE THE COSTUMER RELATED COLUMNS FROM TRANSACTIONS.


CREATE TEMP TABLE temp_customers AS
SELECT customerid,
customer_name,
customer_surname,
shipping_state,
loyalty_discount
FROM transactions

CREATE TABLE customers AS
SELECT DISTINCT * --> WE JUST ADD ONE RECORD PER CUSTOMER IN ORDER TO AVOID DUPLICATE RECORDS IN THE NEW TABLE.
FROM temp_customers

SELECT COUNT(*)
FROM 
(
	SELECT DISTINCT *
	FROM customers

) AS TMP --> OK, 942 UNIQUE RECORDS ABOUT CUSTOMERS.

ALTER TABLE transactions
DROP COLUMN customer_name,
DROP COLUMN customer_surname,
DROP COLUMN shipping_state,
DROP COLUMN loyalty_discount;

SELECT * FROM transactions --> COLUMNS SUCCESSFULY DELETED.

-- 3.2) WHAT ABOUT item AND description? --> THESE COLUMNS MEETS THE CRITERIA OF THE 2NF, BOTH DEPENDS ON THE WHOLE OF THE CANDIDATE KEYS.
--											 WE CANNOT IDENTIFY THE PUCHASED ITEM ONLY KNOWING THE timestampsec OR THE customerid.

-- 3.3) CONDITIONS 1 AND 2 CHECKED! --> 2NF CONFIRMED.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

/*
-- PART 4: IS THE TABLE IN THIRD NORMAL FORM? (3NF)?

CONDITION A) IS THE TABLE IN THE 2NF? --> CONFIRMED.
CONDITION B) EVERY NON PRIME ATTRIBUTE IS NON-TRANSITIVELY DEPENDNING ON EVERY CANDIDATE KEY.
*/

-- 4.1) CHECKING CUSTOMERS TABLE

SELECT * FROM customers --> CONFIRMED, CUSTOMERS TABLE IS IN 3NF.

-- Note: if the loyalty discount would depends on the state, in that case the table would not be in the 3NF and we would need to create a new table for each state and the discount related to each of them.

-- 4.2) CHECKING TRANSACTIONS TABLE

SELECT * FROM transactions --> NO, description AND retail_price DEPENDS ON THE item KEY.

-- IN ORDER TO COMPLETE THE 3NF WE NEED TO CREATE A NEW SEPARATE TABLE FOR ITEMS AND DELETE THE ITEM RELATED COLUMNS FROM TRANSACTIONS.

CREATE TEMP TABLE temp_items AS
SELECT item,
description,
retail_price
FROM transactions

CREATE TABLE items AS
SELECT DISTINCT * --> WE JUST ADD ONE RECORD PER ITEM IN ORDER TO AVOID DUPLICATE RECORDS IN THE NEW TABLE.
FROM temp_items

SELECT COUNT(*)
FROM 
(
	SELECT DISTINCT *
	FROM items

) AS TMP --> OK, 126 UNIQUE RECORDS ABOUT ITEMS.

ALTER TABLE transactions
DROP COLUMN description,
DROP COLUMN retail_price;

SELECT * FROM transactions --> COLUMNS SUCCESSFULY DELETED.


-- 4.3) CHECKING CUSTOMERS TABLE

SELECT * FROM items --> CONFIRMED, ITEMS TABLE IS IN 3NF.

-- 4.4) CONDITIONS 1 AND 2 CHECKED! --> 3NF CONFIRMED FOR ALL TABLES.
