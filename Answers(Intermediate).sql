-- 20. Categories, and the total products in each category
-- For this problem, we’d like to see the total number of products in each
-- category. Sort the results by the total number of products, in descending
-- order.

SELECT CategoryName, COUNT(ProductID) AS [count]
FROM (
     SELECT CategoryName, ProductID
FROM Categories, Products
WHERE Products.CategoryID = Categories.CategoryID
         ) S
GROUP BY CategoryName
ORDER BY [count] DESC;

-- or without subqueries

SELECT CategoryName, COUNT(Products.ProductID) AS [count]
FROM Categories, Products
WHERE Categories.CategoryID = Products.CategoryID
GROUP BY CategoryName
ORDER BY [count] DESC;

-- 21. Total customers per country/city
-- In the Customers table, show the total number of customers per Country
-- and City.

SELECT Country,City, COUNT(CustomerID) AS TotalCustomer
FROM Customers
GROUP BY Country, City
ORDER BY TotalCustomer DESC;


-- 22. Products that need reordering
-- What products do we have in our inventory that should be reordered?
-- For now, just use the fields UnitsInStock and ReorderLevel, where
-- UnitsInStock is less than the ReorderLevel, ignoring the fields
-- UnitsOnOrder and Discontinued.
-- Order the results by ProductID.

SELECT ProductID, ProductName, UnitsInStock, ReorderLevel FROM Products
WHERE UnitsInStock < ReorderLevel;


-- 23. Products that need reordering, continued
-- Now we need to incorporate these fields—UnitsInStock, UnitsOnOrder,
-- ReorderLevel, Discontinued—into our calculation. We’ll define
-- “products that need reordering” with the following:
-- UnitsInStock plus UnitsOnOrder are less than or equal to ReorderLevel
-- The Discontinued flag is false (0).

SELECT ProductID, ProductName, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued
FROM Products
WHERE UnitsInStock + Products.UnitsOnOrder <= ReorderLevel
        AND
      Discontinued = 0;


-- 24. Customer list by region
-- A salesperson for Northwind is going on a business trip to visit
-- customers, and would like to see a list of all customers, sorted by
-- region, alphabetically.
-- However, he wants the customers with no region (null in the Region
-- field) to be at the end, instead of at the top, where you’d normally find
-- the null values. Within the same region, companies should be sorted by
-- CustomerID.

SELECT CustomerID, CompanyName, Region
FROM Customers
ORDER BY IIF(Region IS NULL, 1, 0);

-- 25. High freight charges
-- Some of the countries we ship to have very high freight charges. We'd
-- like to investigate some more shipping options for our customers, to be
-- able to offer them lower freight charges. Return the three ship countries
-- with the highest average freight overall, in descending order by average
-- freight.

SELECT TOP 3 ShipCountry, AVG(Freight) AverageFreight FROM Orders
GROUP BY ShipCountry
ORDER BY AverageFreight DESC;

-- 26. High freight charges - 2015
-- We're continuing on the question above on high freight charges. Now,
-- instead of using all the orders we have, we only want to see orders from
-- the year 2015.

SELECT TOP 3 ShipCountry, AVG(Freight) AverageFreight FROM Orders
WHERE YEAR(OrderDate) = 2015
GROUP BY ShipCountry
ORDER BY AverageFreight DESC;


-- 27. High freight charges with between
-- Another (incorrect) answer to the problem above is this:
Select Top 3
ShipCountry
,AverageFreight = avg(freight)
From Orders
Where
OrderDate between '1/1/2015' and '12/31/2015'
Group By ShipCountry
Order By AverageFreight desc;
-- Notice when you run this, it gives Sweden as the ShipCountry with the
-- third highest freight charges. However, this is wrong - it should be
-- France.
-- What is the OrderID of the order that the (incorrect) answer above is
-- missing?

-- explanation


-- 28. High freight charges - last year
-- We're continuing to work on high freight charges. We now want to get
-- the three ship countries with the highest average freight charges. But
-- instead of filtering for a particular year, we want to use the last 12
-- months of order data, using as the end date the last OrderDate in Orders.


DECLARE @D DATE = ( SELECT MAX(OrderDate) FROM Orders );
SELECT TOP 3 ShipCountry, AVG(Freight) AverageFreight
FROM Orders
WHERE OrderDate > ( DATEADD( MONTH, -12, @D ) )
GROUP BY ShipCountry
ORDER BY AverageFreight DESC;


-- 29. Inventory list
-- We're doing inventory, and need to show information like the below, for
-- all orders. Sort by OrderID and Product ID.

SELECT E.EmployeeID, LastName, O.OrderID, ProductName, Quantity
FROM Employees E
        INNER JOIN Orders O on E.EmployeeID = O.EmployeeID
        INNER JOIN OrderDetails OD on O.OrderID = OD.OrderID
        INNER JOIN Products P on OD.ProductID = P.ProductID
ORDER BY OrderID, P.ProductID;


-- 30. Customers with no orders
-- There are some customers who have never actually placed an order.
-- Show these customers.

SELECT CustomerID Customers_CustomerID, NULL AS Orders_CustomerID
FROM Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Orders
    );

-- or with join

SELECT C.CustomerID Customers_CustomerID, OrderID Orders_CustomerID
FROM Customers C
        LEFT JOIN Orders O on C.CustomerID = O.CustomerID
WHERE OrderID IS NULL;


-- 31. Customers with no orders for EmployeeID 4
-- One employee (Margaret Peacock, EmployeeID 4) has placed the most
-- orders. However, there are some customers who've never placed an order
-- with her. Show only those customers who have never placed an order
-- with her.


SELECT CustomerID, NULL FROM Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID
FROM Employees E
    LEFT JOIN Orders O on E.EmployeeID = O.EmployeeID
WHERE E.EmployeeID = '4'
    );