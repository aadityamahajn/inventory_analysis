--ABC Aanlysis
--ABC analysis is used to divide SKUs into high, medium, and low value to the company.
--It can be calculated from total stock, total revenue, or total profit.
------------------------------------------------------------------------------
DROP TABLE total_stock_by_brand;
-----------------------------------
--Creating A, B, C category according to SKUs contribution in revenue and profits
CREATE TABLE total_stock_by_brand(
       brand INT,
       total_value FLOAT,
       quantity INT,
       avgprice FLOAT,
       avgpaid FLOAT,
       avg_markup FLOAT,
	   avgprofit FLOAT,
	   current_stock INT,
	   abc_class VARCHAR(32)
)

-----------------------------------
INSERT INTO total_stock_by_brand
WITH BrandAverages AS (
    SELECT brand, avgprice
    FROM total_stock_sold_prices
),
total_stock_by_brand AS (
    SELECT
        ba.brand,
        COALESCE(tpb.total_value, 0) AS total_value,
        COALESCE(tpb.quantity, 0) AS quantity,
        COALESCE(tpb.avgprice, ba.avgprice) AS avgprice,
        tpb.avgpaid,
        tpb.avg_markup,
        tpb.avgprofit
    FROM BrandAverages AS ba
    LEFT JOIN total_profit_by_brand AS tpb ON ba.brand = tpb.brand
),
CurrentStock AS (
    SELECT
        "Brand" AS brand,
        SUM("onHand") AS current_stock
    FROM
        "EndInv"
    GROUP BY
        "Brand"
),
RankedTotalStock AS (
    SELECT
        tsb.brand,
        tsb.total_value,
        tsb.quantity,
        tsb.avgprice,
        tsb.avgpaid,
        tsb.avg_markup,
        tsb.avgprofit,
        COALESCE(cs.current_stock, 0) AS current_stock,
        RANK() OVER (ORDER BY tsb.total_value DESC) as rank_num,
        SUM(tsb.total_value) OVER (ORDER BY tsb.total_value DESC) as running_cumulative_value,
        SUM(tsb.total_value) OVER () as total_total_value
    FROM
        total_stock_by_brand AS tsb
    LEFT JOIN
        CurrentStock AS cs ON tsb.Brand = cs.Brand
)
  SELECT
        brand,
        total_value,
        quantity,
        avgprice,
        avgpaid,
        avg_markup,
        avgprofit,
        current_stock,
        CASE
            WHEN running_cumulative_value / total_total_value < 0.8 THEN 'A'
            WHEN running_cumulative_value / total_total_value < 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM RankedTotalStock;
------------------------------------
SELECT * FROM total_stock_by_brand;
----------------------------------------------------------------------
-- Aggrigate the table according to ABC Analysis
 SELECT 
        abc_class,
        COUNT(abc_class) AS SKUs,
        SUM(Quantity) AS Quantity_sold,
        SUM(total_value) AS total_profit,
        SUM(current_stock) AS current_stock
    FROM total_stock_by_brand  
    GROUP BY abc_class

