USE customer_value;

-- 1. THE CORE SPLIT: LOYALTY VS DISCOUNT DEPENDENCY: Business Insight: Proves whether the brand is building genuine affinity or just training customers to wait for sales.

SELECT
    CASE WHEN loyal_b = 1 THEN 'Genuinely Loyal' ELSE 'Discount Dependent' END AS loyalty_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS percent_of_base,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend_usd,
    ROUND(AVG(previous_purchases), 1) AS avg_tenure,
    ROUND(AVG(discount_applied), 3) AS avg_promo_dependency
FROM customers
GROUP BY loyalty_type
ORDER BY avg_spend_usd DESC;


-- 2. SEGMENTATION & SUBSCRIPTION PARADOX: Business Insight: Shows that the subscription program is failing. 
-- 'Organic Loyals' have 0% subscription rates, while 'Promo Dependent' customers dominate it, treating it as a discount vehicle rather than a loyalty tier.

SELECT
    segment,
    COUNT(*) AS n,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS percent_of_base,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend_usd,
    ROUND(SUM(`purchase_amount_(usd)`), 0) AS total_revenue,
    ROUND(AVG(previous_purchases), 1) AS avg_tenure,
    ROUND(AVG(subscription_status) * 100, 1) AS percent_subscribed
FROM customers
GROUP BY segment
ORDER BY avg_spend_usd DESC;


-- 3. ROOT CAUSE ANALYSIS: THE GENDER DIVIDE: Business Insight: The discount problem is structural. 
-- Men make up the majority of the base (68%) but have high discount dependency. 
-- Women have 0% discount dependency and ~72% loyalty. Fixing the acquisition mix fixes the margins.

SELECT
    gender,
    COUNT(*) AS n,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS percent_of_base,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend_usd,
    ROUND(AVG(discount_applied), 3) AS promo_dependency,
    ROUND(AVG(loyal_b) * 100, 1) AS percent_loyal
FROM customers
GROUP BY gender
ORDER BY percent_loyal DESC;


-- 4. GEOGRAPHIC OPPORTUNITY: BRAND PULL INDEx: Business Insight: Ranks states by genuine organic affinity. 
-- High 'Brand Pull Index' indicates areas where marketing should aggressively expand because customers buy at full price.

SELECT
    location AS state,
    COUNT(*) AS n,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend,
    ROUND(AVG(discount_applied), 3) AS promo_dep,
    ROUND(AVG(`purchase_amount_(usd)`) - (AVG(discount_applied) * 20), 2) AS brand_pull_index,
    ROUND(AVG(loyal_b) * 100, 1) AS percent_loyal
FROM customers
GROUP BY location
HAVING COUNT(*) >= 15          
ORDER BY brand_pull_index DESC
LIMIT 10;

-- 5. IDEAL CUSTOMER PROFILE (MARKETING TARGET): Business Insight: Identifies the exact demographic to hand to Facebook/Google ads.
-- The group with the highest loyalty rate is the most profitable acquisition target.

SELECT
    gender,
    CASE
        WHEN age < 25 THEN '18-24'
        WHEN age < 35 THEN '25-34'
        WHEN age < 45 THEN '35-44'
        WHEN age < 55 THEN '45-54'
        ELSE '55+'
    END AS age_band,
    COUNT(*) AS n,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend,
    ROUND(AVG(discount_applied), 3) AS promo_dep,
    ROUND(AVG(loyal_b) * 100, 1) AS percent_loyal
FROM customers
GROUP BY gender, age_band
ORDER BY percent_loyal DESC
LIMIT 10;


-- 6. ACQUISITION MIX SIMULATION: Business Insight: Shows the financial lift of shifting from the current 68% Male baseline to a balanced 50/50 gender acquisition strategy. Pure margin gain.

SELECT
    'Current Mix (32% Female / 68% Male)' AS scenario,
    COUNT(*) AS total_customers,
    SUM(loyal_b) AS loyal_customers,
    ROUND(AVG(loyal_b) * 100, 1) AS loyalty_rate_percent,
    ROUND(AVG(`purchase_amount_(usd)`), 2) AS avg_spend
FROM customers

UNION ALL

SELECT
    'Simulated 50/50 Mix' AS scenario,
    (SELECT COUNT(*) FROM customers WHERE gender = 'Female') * 2 AS total_customers,
    
    (SELECT SUM(loyal_b) FROM customers WHERE gender = 'Female') +
    (SELECT ROUND(AVG(loyal_b) * (SELECT COUNT(*) FROM customers WHERE gender = 'Female')) 
     FROM customers WHERE gender = 'Male') AS loyal_customers,
     
    ROUND(
        ((SELECT AVG(loyal_b) FROM customers WHERE gender = 'Female') * 0.5 + 
         (SELECT AVG(loyal_b) FROM customers WHERE gender = 'Male') * 0.5) * 100
    , 1) AS loyalty_rate_percent,
    
    ROUND(
        (SELECT AVG(`purchase_amount_(usd)`) FROM customers WHERE gender = 'Female') * 0.5 +
        (SELECT AVG(`purchase_amount_(usd)`) FROM customers WHERE gender = 'Male') * 0.5
    , 2) AS avg_spend;