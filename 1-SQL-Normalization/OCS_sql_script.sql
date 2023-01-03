/*
				-- ONLINE CLOTHING STORE - OCS --
				-- NORMALIZATION PROJECT --

WE HAVE BEEN TASKED TO INVESTIGATE THE CURRENT DISING OF THE DATABASE.
IF THE CURRENT DESIGN IS INEFFICIENT WE NEED TO REDISING IT.

WE RECEIVE A PART OF THE CURRENT DATABASE THAT REPRESENTS THE SELLS OF THE LAST 3 DAYS.

IT INCLUDES ONLY 1 TABLE, WITH SALES, CUSTOMERS AND PRODUCT DETAILS.

*/

-- CREATING THE UNIQUE TABLE OF THE CURRENT DATABASE --

CREATE TABLE transactions (
    transactionid varchar,
    timestampsec timestamp,
    customerid varchar,
    firstname varchar,
    surname varchar,
    shipping_state varchar,
    item varchar,
    description varchar,
    retail_price float(2),
    loyalty_discount float(2)
);

-- IMPORTING THE CSV FILE RECEIVED FROM THE CLIENT --
-- IT INCLUDES 3455 RECORDS FROM THE LAST 3 DAYS OF SELLINGS --

COPY transactions 
FROM '/Users/Shared/OCS_database_example.csv' 
DELIMITER ',' 
CSV HEADER;

-- CONTROL of how many records were imported to double check if we have all the data from the CSV in our database.

SELECT COUNT(*)
FROM transactions -- 3455 Records

SELECT *
FROM transactions
LIMIT 10 -- The data was imported succesfully.

/*
IS IT IN THE 1ST NORMAL FORM?
1) DOES THE TABLE INCLUDES CELLS WITH MORE THAN ONE VALUE INSIDE? --> Yes!, for customer_name, it includes the name + surname.
2) IS THERE ANY DUPLICATED ROW? --> SELECT COUNT(*) FROM (SELECT DISTINCT * FROM TRANSACTIONS) --> 3455 RECORDS --> No duplicated rows!, this rule is ok!
*/

/* 
CHECK 2nd NORMAL FORM?
1) IS THE TABLE IN THE 1st NORMAL FORM? --> Yes!
2) CANDIDATE_KEYS --> We need to understand what is the propose of the table --> it is about to document each transactions --> the intention of the table for every single transaction to be unique!

Thinking on this we can create a list of candidate_keys:
- Transactionid: it is a candidate_key
- Timestamp of the transaction: can it on its onw be a candidate_key? --> no, there is the possibility of having 2 transactions at the same time.
- Timestamp + item_id: this combination cant be a candidate key, we can have at the same time 2 different customers purchasing the same item.
- Timestamp + customer_id: this combubination could be a candidate_key --> maybe if there are robots generating the transactions there could be more than one transaction
at the same time for the same customer, but this is almost imposible --> we will assume that is not possible for this project.

- Prime Attributes: Attributes that are part at least of one candidate_key: until now we have 3 prime attributes: transactionid, timestampsec and customerid.

- NonPrime Attributes: every non prime attribute of the table is dependen on the whole of every candidate_key?

No, for example firsname does not depends on the whole of the candidate key timestamp + customer_id, it depends only in a apart of it, the customer_id. Same for lastname, shipping_state
and loyalty_price.

Because of this in order to complete the 2NF we need to create a new separate table for customers.

- What about Itemid and Item Description?, Yes, these columns meets the criteria of the 2NF: they dependes on the whole of the candidate keys!, I cannot idenfity the item based only in the timestamp o the clientid.

*/

/* 
CHECK 3rd NORMAL FORM?
1) IS THE TABLE IN THE 2NF? --> Yes!
2) every non prime attribute is non-transitively depending on every candidate key --> because we have 2 tables now, we need to check both.

SELECT * FROM customers --> all the non prime attributes depends directly to the customer_id --> this table is already in the 3NF.

3NF confirmed for customers

-- Note: if the loyalty discount would depends on the state, in that case the table would not be in the 3NF and we will need to create a new table for each state and the discount related to that state.

SELECT * FROM transactions --> Not all non prime attributes depends directly to every candidate key, the columns description and retail_price depends on the itemid key.

In order to confirm the 3NF on this database we will need to create a separate table for Items and clean the transaction table as we did before for customers.

*/

-- 1 STEP: CREATING THE CUSTOMER_DETAILS TABLE --

CREATE TEMP TABLE temp_customers AS
SELECT customerid,
	   firstname,
	   surname,
	   shipping_state,
	   loyalty_discount
FROM transactions

SELECT * FROM temp_customers -- 3455 Records -- Ok.

-- 1.1 STEP: Deleteng duplicated records from temp_customers
-- 1.2 STEP: Saving it into a new table in our database.

SELECT DISTINCT *
FROM temp_customers -- 942 Unique records about customers.

CREATE TABLE customers AS
SELECT DISTINCT *
FROM temp_customers

SELECT * FROM customers

-- 1.3 STEP: Deleting the customer related columns from transactions table

ALTER TABLE transactions
DROP COLUMN firstname,
DROP COLUMN surname,
DROP COLUMN shipping_state,
DROP COLUMN loyalty_discount

SELECT * FROM transactions --> deleting processs succressfully.

-- 2 STEP: In order to normalize in the 3rd form this database, we need to create a table for items + description and retail_price.

CREATE TEMP TABLE temp_items AS
SELECT item,
	   description,
	   retail_price
FROM transactions

SELECT * FROM temp_items --> 3455 records

SELECT DISTINCT * FROM temp_items --> 126 unique items.

-- 2.1 STEP: Deleteng duplicated records from temp_customers
-- 2.2 STEP: Saving it into a new table in our database.

CREATE TABLE items AS
SELECT DISTINCT *
FROM temp_items

SELECT * FROM items

-- 2.3 STEP: Deleting the items related columns from transactions table

ALTER TABLE transactions
DROP COLUMN description,
DROP COLUMN retail_price

SELECT * FROM transactions --> deleting processs succressfully.

-- 3 STEP: Cheching the 3rd form of normalization

SELECT * FROM transactions
SELECT * FROM items
SELECT * from customers

-- Now we have 3 tables instead of only 1, without any duplicated row and every non-prim attribute provide a fact about the key of the table.

