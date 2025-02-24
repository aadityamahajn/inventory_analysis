CREATE TABLE full_sales(
           brand INT,
		   salesdate TEXT,
		   salesquantity INT
)
-----------------------------
INSERT INTO full_sales
WITH SimpSales AS (
    SELECT
        "Brand",
        "SalesDate",
        SUM("SalesQuantity") AS TotalSalesQuantity
    FROM
        "SalesFINAL"
    GROUP BY
        "Brand",
        "SalesDate"
),
Dates AS (
    SELECT DISTINCT b."Brand", s."SalesDate"  
    FROM (SELECT DISTINCT "Brand" FROM "SalesFINAL") AS b  
    CROSS JOIN (SELECT DISTINCT "SalesDate" FROM "SalesFINAL") AS s 
    ORDER BY b."Brand", s."SalesDate"
)
SELECT
    d."Brand",
    d."SalesDate",
    COALESCE(s.TotalSalesQuantity, 0) AS SalesQuantity
FROM
    Dates d
LEFT JOIN
    SimpSales s ON d."Brand" = s."Brand" AND d."SalesDate" = s."SalesDate"
ORDER BY d."Brand", d."SalesDate";
----------------------------------------
SELECT * FROM full_sales
------------------------------------------------------------------
--Calculate covariance by dividing the sale quantity's standard deviation by its mean
--To ensures X, Y, and Z will be equally distributed among SKUs that have been sold at least three times.
--In reality, X, Y, and Z are not likely to be equally represented and should be calculated based on predetermined thresholds.

DROP TABLE salesagg
-------------------------------------
CREATE TABLE salesagg(
       brand INT,
       sales_mean FLOAT,
	   sales_std FLOAT,
	   sales_cov FLOAT,
	   xyz_class VARCHAR(32)
)
-------------------------------------
INSERT INTO salesagg
WITH SalesAgg AS (
    SELECT
        Brand,
        AVG(SalesQuantity) AS sales_mean,
        STDDEV(SalesQuantity) AS sales_std,
        CAST(STDDEV(SalesQuantity) AS FLOAT) / NULLIF(CAST(AVG(SalesQuantity) AS FLOAT), 0) AS sales_cov  -- Handle zero means
    FROM
        full_sales 
    GROUP BY
        Brand
),
Quantiles AS (
  SELECT
    PERCENTILE_CONT(0.33333) WITHIN GROUP (ORDER BY sales_cov) as X_threshold,
    PERCENTILE_CONT(0.66666) WITHIN GROUP (ORDER BY sales_cov) as Y_threshold
  FROM SalesAgg
)
SELECT
    sa.Brand,
    sa.sales_mean,
    sa.sales_std,
    sa.sales_cov,
    CASE
        WHEN sa.sales_cov < q.X_threshold THEN 'X'
        WHEN sa.sales_cov >= q.X_threshold AND sa.sales_cov < q.Y_threshold THEN 'Y'
        WHEN sa.sales_cov >= q.Y_threshold THEN 'Z'
        ELSE NULL 
    END AS xyz_class
FROM
    SalesAgg sa
CROSS JOIN Quantiles q  
ORDER BY
    sa.sales_cov;
-------------------------------------
SELECT * FROM salesagg;
-------------------------------------------------------------------------------

CREATE TABLE abc_xyz_category AS
SELECT 
    tsb.*,
    COALESCE(sa.xyz_class, 'Z') AS xyz_class  
FROM 
    total_stock_by_brand tsb
LEFT JOIN 
    salesagg sa ON tsb.Brand = sa.Brand;
--------------------------------
SELECT * FROM abc_xyz_category;


