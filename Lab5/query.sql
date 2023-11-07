-- ZADANIE 8a
SELECT OrderDate, COUNT(OrderQuantity) as Orders_cnt 
FROM dbo.FactInternetSales
GROUP BY OrderDate HAVING COUNT(OrderQuantity) < 100
ORDER BY Orders_cnt DESC;

-- ZADANIE 8b
WITH SortUnitPricePerDate AS (
  SELECT 
    OrderDate,
	ProductKey,
	CustomerKey,
    UnitPrice,
    ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC) AS RowNumber
  FROM dbo.FactInternetSales
)
SELECT OrderDate, ProductKey, CustomerKey, UnitPrice
FROM SortUnitPricePerDate
WHERE RowNumber <= 3
ORDER BY OrderDate, RowNumber; 