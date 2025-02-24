SELECT * FROM salesagg;


--Safety Stock 
--Concat the results and adding new column in exisiting table
ALTER TABLE abc_xyz_category
ADD COLUMN abc_xyz_class VARCHAR(32);
----------------
UPDATE abc_xyz_category
SET abc_xyz_class = CONCAT(abc_class,xyz_class)
-------------------------------------------------------------------

-- Finding service factor with help of probablity values and normal distribution 
ALTER TABLE abc_xyz_category
ADD COLUMN service_factor FLOAT; 
---------------
WITH ServiceLevels AS (
    SELECT 'AX' AS class, 0.97 AS service_level UNION ALL
    SELECT 'AY', 0.95 UNION ALL
    SELECT 'AZ', 0.93 UNION ALL
    SELECT 'BX', 0.91 UNION ALL
    SELECT 'BY', 0.90 UNION ALL
    SELECT 'BZ', 0.89 UNION ALL
    SELECT 'CX', 0.85 UNION ALL
    SELECT 'CY', 0.80 UNION ALL
    SELECT 'CZ', 0.70
),
ServiceFactors AS (
    SELECT
        class,
        ROUND(ABS(CASE
            WHEN service_level < 0.5 THEN SQRT(-2*LN(service_level)) - ((2.30753 + 0.27061*SQRT(-2*LN(service_level)))/(1 + 0.99229*SQRT(-2*LN(service_level))))
            ELSE -SQRT(-2*LN(1-service_level)) + ((2.30753 + 0.27061*SQRT(-2*LN(1-service_level)))/(1 + 0.99229*SQRT(-2*LN(1-service_level))))
        END), 4) AS service_factor  
    FROM 
)
UPDATE abc_xyz_category
SET service_factor = sf.service_factor
FROM ServiceFactors sf  
WHERE abc_xyz_category.abc_xyz_class = sf.class;  
-------------------------------------------------------------
SELECT * FROM abc_xyz_category;
-------------------------------------------------------------
--Calculating safety stock also requires the mean and standard deviation of quantities sold,
--which have already been determined, and the mean and standard deviation of lead times 
--(the time between ordering a SKU and receiving it).

CREATE TABLE purchase_agg AS
WITH purchases AS (
  SELECT
    "Brand" AS Brand,
    ("ReceivingDate"::date - "PODate"::date) AS lead_time
  FROM
    "PurchasesFINAL"
)
SELECT
  Brand,
  AVG(lead_time) AS lead_time_mean,
  STDDEV(lead_time) AS lead_time_std
FROM
  purchases
GROUP BY
  Brand;
---------------------------------------------------------
SELECT * FROM purchase_agg;
SELECT * FROM salesagg;
---------------------------------------------------------
--Calculating safety stock
-- Finding EOQ (Economic Order Quantity)
--Calculating recommeded stock

CREATE TABLE safety_stock AS(
SELECT
    a.*,
	s.sales_mean,
	s.sales_std,
	p.lead_time_mean,
	p.lead_time_std,
    ROUND(
        a.service_factor *
        SQRT(
            p.lead_time_mean * POWER(s.sales_std, 2) +
            s.sales_mean * POWER(p.lead_time_std, 2)
        )
    ) AS safety_stock,
    ROUND(SQRT(2 * s.sales_mean * 30 / (a.avgprice * 0.1 / 365))) AS EOQ,
    ROUND(
        a.service_factor *
        SQRT(
            p.lead_time_mean * POWER(s.sales_std, 2) +
            s.sales_mean * POWER(p.lead_time_std, 2)
        ) +
        SQRT(2 * s.sales_mean * 30 / (a.avgprice * 0.1 / 365))
    ) AS rec_stock  -- Added rec_stock calculation
FROM abc_xyz_category a
LEFT JOIN salesagg s ON a.Brand = s.Brand
LEFT JOIN purchase_agg p ON a.Brand = p.Brand)
--------------------------------------------------------
SELECT * FROM safety_stock;
--------------------------------------------------------
--Calculating overstock and understock

CREATE TABLE needed_stock AS (
WITH current_stock AS (
    SELECT
        "Brand" AS Brand,
        SUM("onHand") AS current_stock
    FROM
        "EndInv"
    GROUP BY
        "Brand"
),
calculated_inv AS (
    SELECT
        ss.*,
        COALESCE(cs.current_stock, 0) as current_stock1  
    FROM
        safety_stock ss
    LEFT JOIN
        current_stock cs ON ss.Brand = cs.Brand
),
final_needed_stock AS (
    SELECT
        ci.*, 
        GREATEST(0, ci.rec_stock - ci.current_stock1) AS understock_quantity,
        GREATEST(0, ci.current_stock1 - ci.rec_stock) AS overstock_quantity
    FROM calculated_inv ci  
)
SELECT
    *,
    CASE
        WHEN understock_quantity > rec_stock * 0.1 THEN TRUE
        ELSE FALSE
    END AS is_understocked,
    CASE
        WHEN overstock_quantity > rec_stock * 0.1 THEN TRUE
        ELSE FALSE
    END AS is_overstocked
FROM
    final_needed_stock);
--------------------------------------------------------------
SELECT * FROM needed_stock;
--------------------------------------------------------------
--Display items never sold but held in inventory. These SKUs don't necessarily 
--need to be immediately thrown out, but should be investigated more thoroughly.
SELECT *
FROM needed_stock
WHERE current_stock1 > 0 AND quantity = 0
ORDER BY current_stock DESC;


