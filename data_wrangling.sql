--Inventory tables
SELECT * FROM "BegInv"; -- Beginning stocks
SELECT * FROM "EndInv"; -- Ending stocks
SELECT * FROM "InvoicePurchases"; -- Vendors Invoice
SELECT * FROM "PurchasePricesDec"; -- Purchase Price
SELECT * FROM "PurchasesFINAL"; -- Purchases stock
SELECT * FROM "SalesFINAL"; -- sales stock

-----------------------------------------------------------------------------
-- Transforming Inventory table

Drop table total_stock1; 
---------
CREATE TABLE total_stock1 (
    brand int,
    price float,
	quantity float
);
---------
INSERT INTO total_stock1 (brand, price, quantity)
SELECT "Brand", "Price", SUM("onHand") AS quantity
FROM "BegInv"
GROUP BY "Brand", "Price"
ORDER BY "Brand", "Price";
---------
SELECT * FROM total_stock1;
---------
-- Merging Purchase and purchase price data and transforming that data

Drop table total_stock2; 
---------
CREATE TABLE total_stock2 (
    brand INT,
    price FLOAT,
	quantity FLOAT
);
---------
INSERT INTO total_stock2 (brand, price, quantity)
WITH purchase AS (
    SELECT
        p.*,
        pp."PurchasePrice" AS "PurchasePriceDec" 
    FROM
        "PurchasesFINAL" p
    LEFT JOIN
        "PurchasePricesDec" pp ON p."Brand" = pp."Brand"
)
SELECT 
    "Brand", 
    "PurchasePriceDec" AS price, 
    SUM("Brand") AS quantity 
FROM 
    purchase
GROUP BY 
    "Brand", "PurchasePriceDec"
ORDER BY 
    "Brand", "PurchasePriceDec";
---------
SELECT * FROM total_stock2;

----------
-- UNION total_stock1 and total_stock2
DROP TABLE total_stock;
---------
CREATE TABLE total_stock (
    brand INT,
    price FLOAT,
	quantity FLOAT
);
---------
INSERT INTO total_stock (brand, price, quantity)
SELECT * FROM total_stock1
UNION 
SELECT * FROM total_stock2;
----------
SELECT * FROM total_stock;
----------
Drop table total_stock1;
Drop table total_stock2;

-----------------------------------------------------------------------------------
-- Transforming SalesFINAL
DROP TABLE total_sales_by_brand;
---------
CREATE TABLE total_sales_by_brand (
    brand INT,
	total_value FLOAT,
	quantity FLOAT,
	avgprice FLOAT
);
---------
INSERT INTO total_sales_by_brand (brand, total_value, quantity, avgprice)
WITH BrandSales AS (
    SELECT
        "Brand" AS brand,
        SUM("SalesQuantity") AS TotalSalesQuantity,
        SUM("SalesDollars") AS TotalSalesDollars
    FROM
        "SalesFINAL"  -- Your sales table name
    GROUP BY
        "Brand"
)
SELECT
    Brand,
    ROUND(CAST(TotalSalesDollars AS numeric),2),
	TotalSalesQuantity,
    ROUND(CAST(TotalSalesDollars * 1.0 / TotalSalesQuantity AS numeric),2) AS avg_price 
FROM
    BrandSales;
---------------
SELECT * FROM total_sales_by_brand;
-------------------------------------------------------------------------------------

DROP TABLE total_stock_sold_prices;
--------------
CREATE TABLE total_stock_sold_prices(
brand INT,
avgprice FLOAT,
quantity FLOAT
)
-
INSERT INTO total_stock_sold_prices(brand, avgprice, quantity)
WITH MergedStock AS (
  SELECT
        COALESCE(sap.avgprice, ts.Price) as final_price,
        ts.Brand,
        ts.Quantity
    FROM total_stock ts  
    LEFT JOIN sales_avg_price sap ON ts.Brand = sap.Brand
)
    SELECT 
        Brand,
        MIN(final_price) as avg_price,
        SUM(Quantity) as total_quantity
    FROM MergedStock
    GROUP BY Brand;
--------------
SELECT * FROM total_stock_sold_prices;

--------------------------------------------------------------------------------
-- Transforming PurchaseFNIAL
DROP TABLE paid_by_brand;
--------------------
CREATE TABLE paid_by_brand (
    brand INT,
	total_paid FLOAT,
	quantity FLOAT,
	avgpaid FLOAT
);
---------------------
INSERT INTO paid_by_brand(brand, total_paid, quantity, avgpaid)
WITH BrandPaid AS (
    SELECT
        "Brand" AS brand,
        SUM("Quantity") AS TotalQuantity,
        SUM("Dollars") AS TotalDollars
    FROM
        "PurchasesFINAL" 
    GROUP BY
        "Brand"
)
SELECT
    Brand,
	ROUND(CAST(TotalDollars AS numeric),2),
    TotalQuantity,
    ROUND(CAST(TotalDollars * 1.0 / TotalQuantity AS numeric),2) AS avg_price 
FROM
    BrandPaid;
----------
SELECT * FROM paid_by_brand;
----------------------------------------------------------------------
-- Finding Profit

DROP TABLE total_profit_by_brand;
----------
CREATE TABLE total_profit_by_brand(
             brand INT,
			 total_value FLOAT,
			 quantity INT,
			 avgprice FLOAT,
			 avgpaid FLOAT,
			 avg_markup FLOAT,
			 avgprofit FLOAT
)
-----------------------
INSERT INTO total_profit_by_brand(brand, total_value, quantity, avgprice, avgpaid, avg_markup, avgprofit)
WITH BrandAverages AS (
    SELECT
        tsb.brand AS brand,
        tsb.quantity AS quantity,
        tsb.avgprice AS avgprice,
        pbb.avgpaid,
        ROUND(CAST((tsb.avgprice / NULLIF(pbb.avgpaid, 0) - 1) AS numeric),2) AS avg_markup
    FROM
        total_sales_by_brand AS tsb
    LEFT JOIN
        paid_by_brand AS pbb
    ON
        tsb.brand = pbb.brand
),
CalculatedAverages AS (
    SELECT
        brand,
        COALESCE(avgpaid, avgprice * (1 - (SELECT AVG(avg_markup) FROM BrandAverages))) as calculated_avgpaid
    FROM BrandAverages
),
ProfitCalculations AS (
    SELECT
        ba.brand,  
        ROUND(CAST(ba.avgprice - ca.calculated_avgpaid AS numeric), 2) AS avgprofit
    FROM BrandAverages AS ba
    JOIN CalculatedAverages AS ca ON ba.brand = ca.brand
)
SELECT
    ba.brand,        
	ROUND(CAST(ba.quantity * pc.avgprofit AS numeric), 2) AS total_value,
    ba.quantity,      
    ba.avgprice,      
    ca.calculated_avgpaid, 
    ba.avg_markup,     
    pc.avgprofit      
FROM BrandAverages AS ba
JOIN CalculatedAverages AS ca ON ba.brand = ca.brand
JOIN ProfitCalculations AS pc ON ba.brand = pc.brand;
-----------
SELECT * FROM total_profit_by_brand;

----------------------------------------------------------------------------------
-- All transformed tables 
SELECT * FROM total_stock; -- total stocks
SELECT * FROM total_sales_by_brand; -- sales average price of stocks
SELECT * FROM total_stock_sold_prices; -- stock stock prices 
SELECT * FROM paid_by_brand; -- purchase of stocks
SELECT * FROM total_profit_by_brand; -- total profit by brands

----------------------------------------------------------------------------------
--Initial Observations

-- 1.total SKUs
SELECT COUNT(*) AS total_sku FROM total_stock_sold_prices; 

-- 2.total current stock
SELECT SUM("onHand") AS current_stock FROM "EndInv";

-- 3.total revenue
SELECT ROUND(CAST(SUM(total_value) AS numeric), 2) AS total_revenue FROM total_sales_by_brand;

-- 4.total profit
SELECT ROUND(CAST(SUM(total_value)AS numeric), 2)AS total_profit FROM total_profit_by_brand;

-- 5.minimum and maximum prices
SELECT 
      MIN("SalesPrice") AS min_price,
      MAX("SalesPrice")AS max_price
FROM "SalesFINAL";


