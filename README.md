# Inventory Analysis

## Overview
Bibitor, LLC's substantial sales and inventory data overwhelm existing spreadsheet systems. This project will utilize robust data analysis to enhance inventory management and extract critical sales and purchase trends across their multiple retail locations.
The company provided six business operation datasets for the year ending
* Beginning inventory for 2016
* Ending inventory for 2016
* Purchase invoices for 2016
* Purchase Price
* Sales data

**[Link of datasets](https://www.kaggle.com/datasets/bhanupratapbiswas/inventory-analysis-case-study)**

## Objectives
* Investigate the inventory flow, identify bottlenecks, and recommend strategies to streamline operations and optimize stock holding.
* Determine optimal inventory levels and create a plan to improve inventory accuracy and reduce holding costs.

## Initial Observation
1. **Total SKUs: 11485**
2. **Total current stock: 4885776**
3. **Total revenue: $33,139,375.29**
4. **Total profit: $10,862,291.04**
5. **Items were sold for prices between $0.49 to $4,999.99**
6. **Top 5 SKUs:**

![image alt](https://github.com/aadityamahajn/inventory_analysis/blob/main/graphs/Screenshot%202025-02-27%20074054.png)

## ABC Analysis

**ABC analysis categorizes inventory based on their contribution to value, whether it's sales, profit, or stock volume.This method sorts items by importance, using metrics like revenue or inventory levels, to identify key contributors.SKUs are segmented into tiers using ABC analysis, highlighting those with the most significant impact on the business, measured by factors such as profit or sales.**

https://github.com/aadityamahajn/inventory_analysis/blob/dc943a573f9f7636eab2fbc5df936b2b5339a538/abc_analysis.sql#L21-L79

**Display relative proportions of A, B, and C class inventory.**

https://github.com/aadityamahajn/inventory_analysis/blob/dc943a573f9f7636eab2fbc5df936b2b5339a538/abc_analysis.sql#L83-L91

![image alt](https://github.com/aadityamahajn/inventory_analysis/blob/main/graphs/Screenshot%202025-02-27%20074125.png)
**This company sells mostly a few popular items (A-class, 13% of products, but high volume), while carrying a vast range of rarely sold items (C-class, 70% of products, but low volume). They should consider streamlining their C-class offerings and potentially expanding popular A-class options to improve efficiency.**

## XYZ Analysis

**Combining ABC (value) and XYZ (demand predictability) analysis refines inventory management.  XYZ uses sales quantity covariance to classify items as highly, moderately, or unpredictably demanded, complementing ABC's focus on item value.**

https://github.com/aadityamahajn/inventory_analysis/blob/b4fc905643f0245204da50bc9881f7c0b9de09bc/xyz_analysis.sql#L7-L33

**Calculate a normalized measure of sales quantity variability, acknowledging a simplified equal distribution assumption for frequently sold items, which in practice should be determined by specific, uneven thresholds.**

https://github.com/aadityamahajn/inventory_analysis/blob/b4fc905643f0245204da50bc9881f7c0b9de09bc/xyz_analysis.sql#L51-L84

**Display relative proportions of X, Y, and Z class inventory.**

![image alt](https://github.com/aadityamahajn/inventory_analysis/blob/main/graphs/Screenshot%202025-02-27%20074154.png)

## Recommended stock

![image alt](https://github.com/aadityamahajn/inventory_analysis/blob/main/graphs/Screenshot%202025-02-28%20080908.png)
