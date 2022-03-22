use master;

-- 32. High-value customers
-- We want to send all of our high-value customers a special VIP gift.
-- We're defining high-value customers as those who've made at least 1
-- order with a total value (not including the discount) equal to $10,000 or
-- more. We only want to consider orders made in the year 2016.

SELECT C.CustomerID, CompanyName, O.OrderID, SUM(UnitPrice*Quantity) AS TotalValue
FROM Customers C
        RIGHT JOIN Orders O on C.CustomerID = O.CustomerID
        RIGHT JOIN OrderDetails OD on O.OrderID = OD.OrderID
WHERE YEAR(OrderDate) = 2016
GROUP BY C.CustomerID, CompanyName, O.OrderID
HAVING SUM(UnitPrice*Quantity) > 10000
ORDER BY TotalValue DESC;


-- 33. High-value customers - total orders
-- The manager has changed his mind. Instead of requiring that customers
-- have at least one individual orders totaling $10,000 or more, he wants to
-- define high-value customers as those who have orders totaling $15,000
-- or more in 2016. How would you change the answer to the problem
-- above?

SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalValue
FROM Customers C
        RIGHT JOIN Orders O on C.CustomerID = O.CustomerID
        RIGHT JOIN OrderDetails OD on O.OrderID = OD.OrderID
WHERE YEAR(OrderDate) = 2016
GROUP BY C.CustomerID, CompanyName
HAVING SUM(UnitPrice*Quantity) >= 15000
ORDER BY TotalValue DESC;


-- 34. High-value customers - with discount
-- Change the above query to use the discount when calculating high-value
-- customers. Order by the total amount which includes the discount.

SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalsWithoutDiscount,
       SUM(UnitPrice*Quantity-Discount*UnitPrice*Quantity) AS TotalsWithDiscount
FROM Customers C
        RIGHT JOIN Orders O on C.CustomerID = O.CustomerID
        RIGHT JOIN OrderDetails OD on O.OrderID = OD.OrderID
WHERE YEAR(OrderDate) = 2016
GROUP BY C.CustomerID, CompanyName
HAVING SUM(UnitPrice*Quantity-Discount*UnitPrice*Quantity) >= 10000
ORDER BY TotalsWithDiscount DESC;


-- 35. Month-end orders
-- At the end of the month, salespeople are likely to try much harder to get
-- orders, to meet their month-end quotas. Show all orders made on the last
-- day of the month. Order by EmployeeID and OrderID

SELECT EmployeeID, OrderID, OrderDate FROM Orders
WHERE OrderDate = EOMONTH(OrderDate)
ORDER BY EmployeeID, OrderID;


-- 36. Orders with many line items
-- The Northwind mobile app developers are testing an app that customers
-- will use to show orders. In order to make sure that even the largest
-- orders will show up correctly on the app, they'd like some samples of
-- orders that have lots of individual line items. Show the 10 orders with
-- the most line items, in order of total line items.

SELECT TOP 10 OrderID, COUNT(*) TotalOrderDetails
FROM OrderDetails
GROUP BY OrderID
ORDER BY TotalOrderDetails DESC;


-- 37. Orders - random assortment
-- The Northwind mobile app developers would now like to just get a
-- random assortment of orders for beta testing on their app. Show a
-- random set of 2% of all orders.

DECLARE @TOP INT = ( SELECT COUNT(*)*2/100 FROM Orders )
SELECT TOP (@TOP) OrderID FROM Orders
ORDER BY RAND();

-- 38. Orders - accidental double-entry
-- Janet Leverling, one of the salespeople, has come to you with a request.
-- She thinks that she accidentally double-entered a line item on an order,
-- with a different ProductID, but the same quantity. She remembers that
-- the quantity was 60 or more. Show all the OrderIDs with line items that
-- match this, in order of OrderID.

SELECT OrderID FROM OrderDetails
WHERE Quantity >= 60
GROUP BY OrderID, Quantity
HAVING COUNT(ProductID) > 1
ORDER BY Quantity;


-- 39. Orders - accidental double-entry details
-- Based on the previous question, we now want to show details of the
-- order, for orders that match the above criteria.

SELECT * FROM OrderDetails
WHERE OrderID IN (
                        SELECT OrderID FROM OrderDetails
                        WHERE Quantity >= 60
                        GROUP BY OrderID, Quantity
                        HAVING COUNT(ProductID) > 1
    );


-- 40. Orders - accidental double-entry details, derived table
-- Here's another way of getting the same results as in the previous
-- problem, using a derived table instead of a CTE. However, there's a bug
-- in this SQL. It returns 20 rows instead of 16. Correct the SQL.
-- Problem SQL:

Select
OrderDetails.OrderID
,ProductID
,UnitPrice
,Quantity
,Discount
From OrderDetails
Join (
Select
OrderID
From OrderDetails
Where Quantity >= 60
Group By OrderID, Quantity
Having Count(*) > 1
) PotentialProblemOrders
on PotentialProblemOrders.OrderID = OrderDetails.OrderID
Order by OrderID, ProductID;

-- fixed version with adding distinct
Select DISTINCT
    OrderDetails.OrderID
    ,ProductID
    ,UnitPrice
    ,Quantity
    ,Discount
From OrderDetails
RIGHT Join (
        Select
        OrderID
        From OrderDetails
        Where Quantity >= 60
        Group By OrderID, Quantity
        Having Count(*) > 1
) PotentialProblemOrders
on PotentialProblemOrders.OrderID = OrderDetails.OrderID
Order by OrderID, ProductID;


-- 41. Late orders
-- Some customers are complaining about their orders arriving late. Which
-- orders are late?

SELECT OrderID, CONVERT(DATE, OrderDate) AS OrderDate,
       CONVERT(DATE, RequiredDate) AS RequiredDate,
       CONVERT(DATE, ShippedDate) AS ShippedDate
FROM Orders
WHERE ShippedDate >= RequiredDate;


-- 42. Late orders - which employees?
-- Some salespeople have more orders arriving late than others. Maybe
-- they're not following up on the order process, and need more training.
-- Which salespeople have the most orders arriving late?

SELECT E.EmployeeID, LastName,  COUNT(OrderID) AS TotalLateOrders
FROM Employees E
        RIGHT JOIN (
            SELECT OrderID, EmployeeID, CONVERT(DATE, OrderDate) AS OrderDate,
                               CONVERT(DATE, RequiredDate) AS RequiredDate,
                               CONVERT(DATE, ShippedDate) AS ShippedDate
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) T ON E.EmployeeID = T.EmployeeID
GROUP BY E.EmployeeID, LastName
ORDER BY TotalLateOrders DESC;


-- 43. Late orders vs. total orders
-- Andrew, the VP of sales, has been doing some more thinking some more
-- about the problem of late orders. He realizes that just looking at the
-- number of orders arriving late for each salesperson isn't a good idea. It
-- needs to be compared against the total number of orders per
-- salesperson. Return results like the following:

SELECT E.EmployeeID, LastName, AllOrders, COUNT(OrderID) AS TotalLateOrders
FROM Employees E
        RIGHT JOIN (
            SELECT OrderID, EmployeeID
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) LateOrders ON E.EmployeeID = LateOrders.EmployeeID
        LEFT JOIN (
                        SELECT EmployeeID, COUNT(OrderID) AS AllOrders FROM Orders
                            GROUP BY EmployeeID
    ) AllOrders ON LateOrders.EmployeeID = AllOrders.EmployeeID
GROUP BY E.EmployeeID, LastName, AllOrders
ORDER BY EmployeeID;


-- 44. Late orders vs. total orders - missing employee
-- There's an employee missing in the answer from the problem above. Fix
-- the SQL to show all employees who have taken orders.

SELECT E.EmployeeID, LastName, AllOrders, COUNT(OrderID) AS TotalLateOrders
FROM Employees E
    LEFT JOIN (
                        SELECT EmployeeID, COUNT(OrderID) AS AllOrders FROM Orders
                            GROUP BY EmployeeID
    ) AllOrders ON E.EmployeeID = AllOrders.EmployeeID
        FULL JOIN (
            SELECT OrderID, EmployeeID
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) LateOrders ON E.EmployeeID = LateOrders.EmployeeID
GROUP BY E.EmployeeID, LastName, AllOrders
ORDER BY EmployeeID;


-- 45. Late orders vs. total orders - fix null
-- Continuing on the answer for above query, let's fix the results for row 5
-- - Buchanan. He should have a 0 instead of a Null in LateOrders.

SELECT E.EmployeeID, LastName, AllOrders, COUNT(OrderID) AS TotalLateOrders
FROM Employees E
    LEFT JOIN (
                        SELECT EmployeeID, COUNT(OrderID) AS AllOrders FROM Orders
                            GROUP BY EmployeeID
    ) AllOrders ON E.EmployeeID = AllOrders.EmployeeID
        FULL JOIN (
            SELECT OrderID, EmployeeID
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) LateOrders ON E.EmployeeID = LateOrders.EmployeeID
GROUP BY E.EmployeeID, LastName, AllOrders
ORDER BY EmployeeID;


-- 46. Late orders vs. total orders - percentage
-- Now we want to get the percentage of late orders over total orders.

SELECT E.EmployeeID, LastName, AllOrders, COUNT(OrderID) AS TotalLateOrders,
       COUNT(OrderID)*1.0/AllOrders AS PercentLateOrders
FROM Employees E
    LEFT JOIN (
                        SELECT EmployeeID, COUNT(OrderID) AS AllOrders FROM Orders
                            GROUP BY EmployeeID
    ) AllOrders ON E.EmployeeID = AllOrders.EmployeeID
        FULL JOIN (
            SELECT OrderID, EmployeeID
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) LateOrders ON E.EmployeeID = LateOrders.EmployeeID
GROUP BY E.EmployeeID, LastName, AllOrders
ORDER BY EmployeeID;


-- 47. Late orders vs. total orders - fix decimal
-- So now for the PercentageLateOrders, we get a decimal value like we
-- should. But to make the output easier to read, let's cut the
-- PercentLateOrders off at 2 digits to the right of the decimal point.

SELECT E.EmployeeID, LastName, AllOrders, COUNT(OrderID) AS TotalLateOrders,
     FORMAT(COUNT(OrderID)*1.0/AllOrders, 'N', 'de-de')   AS PercentLateOrders
FROM Employees E
    LEFT JOIN (
                        SELECT EmployeeID, COUNT(OrderID) AS AllOrders FROM Orders
                            GROUP BY EmployeeID
    ) AllOrders ON E.EmployeeID = AllOrders.EmployeeID
        FULL JOIN (
            SELECT OrderID, EmployeeID
                FROM Orders
                WHERE ShippedDate >= RequiredDate
    ) LateOrders ON E.EmployeeID = LateOrders.EmployeeID
GROUP BY E.EmployeeID, LastName, AllOrders
ORDER BY EmployeeID;


-- 48. Customer grouping
-- Andrew Fuller, the VP of sales at Northwind, would like to do a sales
-- campaign for existing customers. He'd like to categorize customers into
-- groups, based on how much they ordered in 2016. Then, depending on
-- which group the customer is in, he will target the customer with
-- different sales materials.
-- The customer grouping categories are 0 to 1,000, 1,000 to 5,000, 5,000
-- to 10,000, and over 10,000.
-- A good starting point for this query is the answer from the problem
-- “High-value customers - total orders. We don’t want to show customers
-- who don’t have any orders in 2016.
-- Order the results by CustomerID.

SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalOrderAmount,
       CustomerGroup = CASE
                WHEN SUM(UnitPrice*Quantity) BETWEEN 0 AND 1000 THEN 'LOW'
                WHEN SUM(UnitPrice*Quantity) BETWEEN 1001 AND 5000 THEN 'MEDIUM'
                WHEN SUM(UnitPrice*Quantity) BETWEEN 5001 AND 10000 THEN 'HIGH'
            ELSE 'VERY HIGH'
    END
FROM Customers C
    LEFT JOIN Orders O on C.CustomerID = O.CustomerID
    LEFT JOIN OrderDetails OD on O.OrderID = OD.OrderID
WHERE YEAR(OrderDate) = 2016
GROUP BY C.CustomerID, CompanyName;


-- 49. Customer grouping - fix null
-- There's a bug with the answer for the previous question. The
-- CustomerGroup value for one of the rows is null.
-- Fix the SQL so that there are no nulls in the CustomerGroup field.

-- Using “between” works well for integer values. However, the value we're
-- working with is Money, which has decimals. So we need to use another

SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalOrderAmount,
       CustomerGroup = CASE
                WHEN SUM(UnitPrice*Quantity) >= 0 AND SUM(UnitPrice*Quantity) < 1000 THEN 'LOW'
                WHEN SUM(UnitPrice*Quantity) >= 1000 AND SUM(UnitPrice*Quantity) < 5000 THEN 'MEDIUM'
                WHEN SUM(UnitPrice*Quantity) >= 5000 AND SUM(UnitPrice*Quantity) <10000 THEN 'HIGH'
            ELSE 'VERY HIGH'
    END
FROM Customers C
    LEFT JOIN Orders O on C.CustomerID = O.CustomerID
    LEFT JOIN OrderDetails OD on O.OrderID = OD.OrderID
WHERE YEAR(OrderDate) = 2016
GROUP BY C.CustomerID, CompanyName;


-- 50. Customer grouping with percentage
-- Based on the above query, show all the defined CustomerGroups, and
-- the percentage in each. Sort by the total in each group, in descending
-- order.

-- DECLARE @P FLOAT = ( SELECT COUNT(*) FROM )
SELECT CustomerGroup, COUNT(CustomerID) AS TotalInGroup, COUNT(CustomerID)*1.0/81 AS PercentageInGroup
FROM (
                     SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalOrderAmount,
                       CustomerGroup = CASE
                                WHEN SUM(UnitPrice*Quantity) >= 0 AND SUM(UnitPrice*Quantity) < 1000 THEN 'LOW'
                                WHEN SUM(UnitPrice*Quantity) >= 1000 AND SUM(UnitPrice*Quantity) < 5000 THEN 'MEDIUM'
                                WHEN SUM(UnitPrice*Quantity) >= 5000 AND SUM(UnitPrice*Quantity) <10000 THEN 'HIGH'
                            ELSE 'VERY HIGH'
                    END
                        FROM Customers C
                            LEFT JOIN Orders O on C.CustomerID = O.CustomerID
                            LEFT JOIN OrderDetails OD on O.OrderID = OD.OrderID
                        WHERE YEAR(OrderDate) = 2016
                        GROUP BY C.CustomerID, CompanyName
         ) C
GROUP BY CustomerGroup
ORDER BY TotalInGroup DESC;


-- 51. Customer grouping - flexible
-- Andrew, the VP of Sales is still thinking about how best to group
-- customers, and define low, medium, high, and very high value
-- customers. He now wants complete flexibility in grouping the
-- customers, based on the dollar amount they've ordered. He doesn’t want
-- to have to edit SQL in order to change the boundaries of the customer
-- groups.
-- How would you write the SQL?
-- There's a table called CustomerGroupThreshold that you will need to
-- use. Use only orders from 2016.

SELECT CustomerID, CompanyName, TotalOrderAmount, CustomerGroupName
FROM (
                 SELECT C.CustomerID, CompanyName, SUM(UnitPrice*Quantity) AS TotalOrderAmount
            FROM Customers C
                    LEFT JOIN Orders O on C.CustomerID = O.CustomerID
                    LEFT JOIN OrderDetails OD on O.OrderID = OD.OrderID
            WHERE YEAR(OrderDate) = 2016
            GROUP BY C.CustomerID, CompanyName
         ) TOA
                LEFT JOIN CustomerGroupThresholds CGT ON TotalOrderAmount BETWEEN CGT.RangeBottom AND CGT.RangeTop;


-- 52. Countries with suppliers or customers
-- Some Northwind employees are planning a business trip, and would like
-- to visit as many suppliers and customers as possible. For their planning,
-- they’d like to see a list of all countries where suppliers and/or customers
-- are based.

SELECT DISTINCT C.Country
FROM Customers C
        LEFT JOIN Orders O on C.CustomerID = O.CustomerID
        LEFT JOIN OrderDetails OD on O.OrderID = OD.OrderID
        LEFT JOIN Products P on OD.ProductID = P.ProductID
        FULL JOIN Suppliers S on P.SupplierID = S.SupplierID
ORDER BY Country;


-- or more efficiently, simple and correct

SELECT Country AS S
FROM Customers
UNION
SELECT Country AS C
FROM Suppliers;


-- 53. Countries with suppliers or customers, version 2
-- The employees going on the business trip don’t want just a raw list of
-- countries, they want more details. We’d like to see output like the
-- below, in the Expected Results.

SELECT DISTINCT C.Country CustomerCountry, S.Country SupplierCountry FROM Customers C
    FULL JOIN Suppliers S ON C.Country = S.Country
ORDER BY CustomerCountry, SupplierCountry;

-- without nulls
SELECT DISTINCT Customers.Country, Suppliers.Country
FROM Customers, Suppliers
WHERE Customers.Country = Suppliers.Country;


-- 54. Countries with suppliers or customers - version 3
-- The output of the above is improved, but it’s still not ideal
-- What we’d really like to see is the country name, the total suppliers, and
-- the total customers.


SELECT COUNTRYS.Country, IIF(CUST.TotalCustomers IS NULL, 0, CUST.TotalCustomers) TotalCustomers,
       IIF(SUP.TotalCustomers IS NULL, 0, SUP.TotalCustomers) TotalSuppliers FROM (
              SELECT Country AS Country
                FROM Customers
                UNION
              SELECT Country
                FROM Suppliers
                  ) COUNTRYS
FULL JOIN (
    SELECT Country, COUNT(CustomerID) AS TotalCustomers FROM Customers
        GROUP BY Country
    ) CUST ON CUST.Country = COUNTRYS.Country
FULL JOIN (
    SELECT Country, COUNT(SupplierID) AS TotalCustomers FROM Suppliers
        GROUP BY Country
    ) SUP ON SUP.Country = COUNTRYS.Country;


-- 55. First order in each country
-- Looking at the Orders table—we’d like to show details for each order
-- that was the first in that particular country, ordered by OrderID.
-- So, we need one row per ShipCountry, and CustomerID, OrderID, and
-- OrderDate should be of the first order from that country.


SELECT ShipCountry, CustomerID, OrderID, OrderDate FROM (
              SELECT RANK() over ( PARTITION BY ShipCountry ORDER BY OrderDate) AS R,
                       ShipCountry, CustomerID, OrderID, OrderDate
                FROM Orders
                  ) RANK
WHERE R = 1;


-- 56. Customers with multiple orders in 5 day period
-- There are some customers for whom freight is a major expense when
-- ordering from Northwind.
-- However, by batching up their orders, and making one larger order
-- instead of multiple smaller orders in a short period of time, they could
-- reduce their freight costs significantly.
-- Show those customers who have made more than 1 order in a 5 day
-- period. The sales people will use this to help customers reduce their
-- costs.
-- Note: There are more than one way of solving this kind of problem. For
-- this problem, we will not be using Window functions.

SELECT First.CustomerID, First.OrderID, First.OrderDate, Last.OrderID, Last.OrderDate
FROM Orders First
    JOIN Orders Last ON First.CustomerID = Last.CustomerID
WHERE First.OrderDate < Last.OrderDate AND DATEDIFF(DAY, First.OrderDate, Last.OrderDate) <= 5
ORDER BY First.CustomerID, First.OrderID;


-- 57. Customers with multiple orders in 5 day period, version 2
-- There’s another way of solving the problem above, using Window
-- functions. We would like to see the following results.


SELECT * FROM (
              SELECT CustomerID, CONVERT(DATE, OrderDate) AS OrderDate,
             CONVERT(DATE, LEAD(OrderDate) over ( PARTITION BY CustomerID ORDER BY CustomerID)) NextDate,
                     DATEDIFF(DAY, OrderDate, LEAD(OrderDate) over ( PARTITION BY CustomerID ORDER BY CustomerID)) Diff
FROM Orders
                  ) Ord
WHERE OrderDate < NextDate AND Diff <= 5
ORDER BY CustomerID;