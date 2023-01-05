---------------- Preparation ----------------

-- a. Create a database called ProductSales --> DONE

-- b. Run the scripts to create the structures.

CREATE TABLE Category (
    CategoryID    integer     PRIMARY KEY,
	CategoryName  varchar(50) NOT NULL,
	Tax           decimal     NOT NULL
);

CREATE TABLE Branch (
    BranchID      integer     PRIMARY KEY,
	BranchName    varchar(50) NOT NULL
);

CREATE TABLE Customer (
    CustomerID    integer     PRIMARY KEY,
	CustomerName  varchar(50) NOT NULL
);

CREATE TABLE SalesRep (
    SalesRepID    integer     PRIMARY KEY,
	SalesRepName  varchar(50) NOT NULL,
	BranchID      integer     NOT NULL REFERENCES Branch (BranchID)
);

CREATE TABLE Orders (
    OrderID       integer     PRIMARY KEY,
	OrderDate     date        NOT NULL,
	CustomerID    integer     NOT NULL REFERENCES Customer (CustomerID),
	SalesRepID    integer     NULL REFERENCES SalesRep (SalesRepID)
);

CREATE TABLE Product (
    ProductID     integer     PRIMARY KEY,
    ProductName   varchar(50) NOT NULL,
    CategoryID    integer     NOT NULL REFERENCES Category (CategoryID),
    Price         decimal     NOT NULL
);

CREATE TABLE OrderDetail (
    OrderDetailID integer     PRIMARY KEY,
    OrderID       integer     NOT NULL REFERENCES Orders (OrderID),
	ProductID     integer     NOT NULL REFERENCES Product (ProductID),
	Discount      decimal     NULL,
	Quantity      integer     NOT NULL
);

-- b. --> DONE
 
-- c. Run the scripts to load the data into the structure created.

COPY Category    FROM '/Users/Shared/Category.csv'    DELIMITER ',' CSV HEADER;
COPY Branch      FROM '/Users/Shared/Branch.csv'      DELIMITER ',' CSV HEADER;
COPY Customer    FROM '/Users/Shared/Customer.csv'    DELIMITER ',' CSV HEADER;
COPY SalesRep    FROM '/Users/Shared/SalesRep.csv'    DELIMITER ',' CSV HEADER;
COPY Orders      FROM '/Users/Shared/Orders.csv'      DELIMITER ',' CSV HEADER;
COPY Product     FROM '/Users/Shared/Product.csv'     DELIMITER ',' CSV HEADER;
COPY OrderDetail FROM '/Users/Shared/OrderDetail.csv' DELIMITER ',' CSV HEADER;

-- c. --> DONE

---------------- Analysis ----------------

-- 2) Query the database to select the number of units, average, standard deviation, max and min product price by category.

SELECT CAT.CategoryName, 
	   COUNT (P.ProductName) Number_Units, 
	   ROUND(AVG(P.Price),2) Avg_Price, 
	   ROUND(STDDEV_SAMP(P.Price),2) STD, 
	   MAX(P.Price) Max_Price, 
	   MIN(P.Price) Min_Price
FROM Product P
INNER JOIN Category CAT
ON P.CategoryID = CAT.CategoryID
GROUP BY CAT.CategoryName
ORDER BY CAT.CategoryName

-- 3) Query the database to select the top 10 best-selling products of all times.
 
SELECT CAT.CategoryName,
	   P.ProductName,
	   SUM(OD.Quantity) Quantity_Sold
FROM Product P
INNER JOIN OrderDetail OD
ON P.ProductID = OD.ProductID
INNER JOIN Category CAT
ON P.CategoryID = CAT.CategoryID
GROUP BY CAT.CategoryName, P.ProductName
ORDER BY Quantity_Sold DESC
LIMIT 10

-- 4) Query the database to select the gross revenue and total tax by year.

SELECT DATE_PART('year',O.OrderDate) Order_Year,
	   SUM(P.Price * OD.Quantity * (1-COALESCE(OD.Discount, 0))) GrossRevenue,
	   ROUND(SUM(P.Price * OD.Quantity * (1-COALESCE(OD.Discount, 0)) * (CAT.Tax/100) ),2) Total_Tax
FROM OrderDetail OD
INNER JOIN Product P
ON P.ProductID = OD.ProductID
INNER JOIN Orders O
ON O.OrderID = OD.OrderID
INNER JOIN Category CAT
ON CAT.CategoryID = P.CategoryID
GROUP BY Order_Year
ORDER BY Order_Year

-- 5) In 2014, customers that purchased more than $ 30,000 in products will be segmented as loyalty members. Discover the list of eligible customers.

SELECT C.CustomerName,
	   DATE_PART('year',O.OrderDate) Order_Year,
	   SUM(P.Price * OD.Quantity * (1-COALESCE(OD.Discount, 0))) GrossRevenue
FROM Orders O
INNER JOIN Customer C
ON C.CustomerID = O.CustomerID
INNER JOIN OrderDetail OD
ON O.OrderID = OD.OrderID
INNER JOIN Product P
ON P.ProductID = OD.ProductID
WHERE (DATE_PART('year',O.OrderDate) = '2014')
GROUP BY Order_Year, C.CustomerName
HAVING SUM(P.Price * OD.Quantity * (1-COALESCE(OD.Discount, 0))) >= 30000
ORDER BY GrossRevenue DESC

/*
-- 6) The sales reps receive a 20% commission fee over the total of the sale. You must calculate the commission of each employee. 
	  Online sales should appear at the list grouped, although they don’t have a specific sales rep name.
*/

SELECT COALESCE(S.SalesRepName,'Online') SalesRep,
	   SUM(P.Price * OD.Quantity * (1-COALESCE(OD.Discount, 0)) * 0.20) Commission
FROM Orders O
INNER JOIN OrderDetail OD
ON O.OrderID = OD.OrderID
INNER JOIN Product P
ON P.ProductID = OD.ProductID
LEFT JOIN SalesRep S
ON S.SalesRepID = O.SalesRepID
GROUP BY S.SalesRepName
ORDER BY Commission DESC

-----------------------------------
-----------------------------------

-- SOURCE OF PROJECT: https://www.superdatascience.com/home -- Kirill Eremenko