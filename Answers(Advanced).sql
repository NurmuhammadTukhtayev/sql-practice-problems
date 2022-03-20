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