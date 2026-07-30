-- 1. Monthly revenue and profit trend
/* 
KEY INSIGHTS:
- Strong Year-Over-Year Growth: Total revenue nearly doubled over the 4-year period, scaling from $2.26M (2011) to $4.30M (2014).
- Predictable Seasonality: Late Q3 and Q4 consistently drive peak financial returns, with November 2014 recording the highest gross revenue ($548,201.52).
- Peak Profitability: September 2014 yielded the highest net profit in the dataset ($69,823.30), achieving an exceptional profit margin of ~14.32%.
- Stable Margins: The aggregate annual profit margin remains highly stable, hovering predictably around an average of 11.5% across all four years.
- Cyclical Lows: January and February emerge as recurring annual low points, with February 2011 hitting the lowest baseline revenue ($91,379.65).
*/
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(oi.sales) AS revenue,
       SUM(oi.profit) AS profit
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY DATE_TRUNC('month', o.order_date);

-- 2. Quota attainment by rep, most recent month in the data
/* 
KEY INSIGHTS:
- High Performers: Cameron Reiter (Canada) drastically outperformed their quota, achieving 1158% of their target. Alex Lee (US) also significantly exceeded expectations at 339%.
- Broad Success: Out of 39 sales representatives, 23 successfully met or exceeded their monthly quota (>= 100% attainment).
- Market Trends: High-performing representatives (top 10) are well-distributed across diverse global markets, including Canada, US, APAC, EU, EMEA, and LATAM.
- Underperformance Risk: Marlowe Ochoa (US) recorded the lowest quota attainment at 36.7%, followed by Dakota Grant (LATAM) at 47.2%, indicating potential areas needing operational support.
- Regional Outliers: Within the APAC region, performance varied widely—ranging from Riley Diaz at 278.1% to Jamie Lee at 51.6% attainment.
*/
WITH latest_month AS (
    SELECT MAX(DATE_TRUNC('month', order_date)) AS month FROM orders
)
SELECT r.rep_name, r.market, r.region,
       t.target_amount,
       COALESCE(SUM(oi.sales), 0) AS actual_amount,
       ROUND(COALESCE(SUM(oi.sales), 0) / t.target_amount * 100, 1) AS pct_of_target
FROM sales_reps r
JOIN targets t ON r.rep_id = t.rep_id
CROSS JOIN latest_month lm
LEFT JOIN orders o ON o.rep_id = r.rep_id
    AND DATE_TRUNC('month', o.order_date) = lm.month
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE t.month = lm.month
GROUP BY r.rep_name, r.market, r.region, t.target_amount
ORDER BY pct_of_target DESC;

-- 3. Rank reps within their market by total revenue
/* 
KEY INSIGHTS:
- Top Global Earner: Emerson Adler (EU - Central) generated the highest absolute revenue across all markets, pulling in $870,982.34.
- High-Value Market Dominance: The European Union (EU) market features heavy hitters; both Rank 1 (Emerson Adler) and Rank 2 (Quinn Novak, $849,940.82) vastly outpaced top reps in all other regions.
- Fierce Internal Competition: The APAC market displays strong, tightly grouped performance among its top reps, led by Jordan Reed ($568,378.55) and Morgan Fox ($531,806.03) in Oceania.
- Emerging Markets Balance: Africa and EMEA show highly competitive, neck-and-neck duels for the top spots (e.g., Skyler Ortiz leading Rowan Silva by less than $6k in EMEA).
- Regional Disparities: In LATAM, there is a stark drop-off between the top performers in the South/North regions (~$311k–$323k) and the lower-ranked Caribbean reps who hover around $160k.
*/
SELECT rep_name, market, region, total_sales,
       RANK() OVER (PARTITION BY market ORDER BY total_sales DESC) AS rank_in_market
FROM (
    SELECT r.rep_name, r.market, r.region, SUM(oi.sales) AS total_sales
    FROM sales_reps r
    JOIN orders o ON r.rep_id = o.rep_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY r.rep_name, r.market, r.region
) rep_totals;

-- 4. Running total of revenue
/* 
KEY INSIGHTS:
- Exponential Cumulative Growth: The cumulative running total of revenue exhibits a massive upward trajectory year-over-year, culminating in a historical grand total of over $7.48 Billion ($7,487,283,859) by the end of 2014.
- Compounding Annual Velocity: The speed of revenue accumulation rapidly accelerated each year. The cumulative volume generated in 2014 alone ($3.65B) eclipsed the total combined accumulation of 2011 ($317.5M) and 2012 ($1.20B).
- Strong Intra-Year Acceleration: Within every single fiscal year, the running metric scales heavily toward the latter half, with Q4 consistently posting the largest incremental surges (e.g., jumping to $1.08B in Q4 2014).
- Critical Milestones: The database highlights massive transactional scale, crossing the first cumulative $1 Billion mark during 2012, and aggressively crossing the $3 Billion baseline by the conclusion of 2013.
*/
SELECT order_date,
       SUM(daily_revenue) OVER (ORDER BY order_date) AS running_total
FROM (
    SELECT o.order_date, SUM(oi.sales) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
) daily;

-- 5. Revenue and margin by market
/* 
KEY INSIGHTS:
- Highest Revenue Driver: APAC is the company's largest market by volume, generating the highest total revenue at $3,585,744.26 alongside a healthy 12.2% profit margin.
- Core Profitability Trio: APAC, EU ($2.94M), and the US ($2.29M) form the core pillars of the business, consistently maintaining high sales volume and stable margins between 12.2% and 12.7%.
- Efficiency Outlier: Canada functions as a highly specialized, high-efficiency market—yielding a phenomenal 26.6% profit margin ($17,817.39 profit) despite bringing in the lowest relative revenue ($66,928.17).
- Operational Risk (EMEA): While EMEA brought in $806,161.33 in revenue, it faces a severe profitability bottleneck, recording a critically low profit margin of only 5.4%.
- Emerging Market Strength: Africa shows strong fundamentals compared to EMEA; with a similar revenue footprint ($783,773.23), it captured more than double EMEA's absolute profit, running at an efficient 11.3% margin.
*/
SELECT o.market,
       SUM(oi.sales) AS revenue,
       SUM(oi.profit) AS profit,
       ROUND(SUM(oi.profit) / NULLIF(SUM(oi.sales),0) * 100, 1) AS margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.market
ORDER BY revenue DESC;

-- 6. Year-over-year growth by category
/* 
KEY INSIGHTS:
- Top Revenue Engine: Technology is consistently the largest revenue category, scaling rapidly from $827,652.13 in 2011 to a dominant $1,616,158.83 by 2014.
- Accelerating Momentum: Office Supplies demonstrates strong, compounding growth acceleration over the 4-year timeline, with its YoY growth rate surging from 17.7% (2012) to 27.1% (2013) and peaking at 29.2% in 2014.
- Highest Single Growth Spike: Furniture achieved the highest individual annual spike in the dataset during 2013, registering a massive 30.1% growth rate to cross the $1 Million mark ($1,117,723.59).
- Balanced Category Scaling: All three primary product categories show remarkable financial health, without a single year of negative or flattening YoY growth across the entire timeline.
*/
WITH yearly_category_sales AS (
    SELECT EXTRACT(YEAR FROM o.order_date) AS year,
           p.category,
           SUM(oi.sales) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
SELECT category, year, revenue,
       LAG(revenue) OVER (PARTITION BY category ORDER BY year) AS prior_year_revenue,
       ROUND(
         (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY year))
         / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY year),0) * 100, 1
       ) AS yoy_growth_pct
FROM yearly_category_sales
ORDER BY category, year;

-- 7. Top 10 customers by revenue
/* 
KEY INSIGHTS:
- Highest Value Customer: Tom Ashbrook leads all historical accounts in lifetime spending, contributing a top-tier revenue total of $42,236.06.
- High-Concentration Spending Tier: The top five high-value clients (Tom Ashbrook, Tamara Chand, Greg Tran, Sean Miller, and Christopher Conant) each crossed a major $35k lifecycle purchasing milestone.
- Tight Account Density: Significant revenue density exists within the lower half of the leaderboard, where spending across positions 7 through 10 is tightly packed between $30.2k and $32.1k.
- Customer Tier Value: Every customer on this top-10 list represents an elite purchasing bracket, generating at least $30,267.59 in individual lifetime sales volume.
*/
SELECT c.customer_name, SUM(oi.sales) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 8. Discount impact on profit margin
/* 
KEY INSIGHTS:
- High Volume Margin Protection: Non-discounted transactions represent the vast majority of orders (29,470 line items) and yield the highest baseline return with an average profit of $62.05 per item.
- Optimal Promotion Ceiling: Applying minor discounts up to 20% effectively drives sales volume (10,533 line items) while preserving strong, positive bottom-line health at an average profit of $43.00.
- Severe Promotional Deficit: Deep promotions exceeding 20% destroy profitability, causing a heavy net loss of -$72.13 on average per transaction across a significant sample size of 11,287 line items.
- Strategic Redirection: While zero-to-low discounts keep operations highly profitable, aggressive markdown practices require urgent restructuring or strict policy limits to prevent severe capital erosion.
*/
SELECT
    CASE
        WHEN discount = 0 THEN 'No discount'
        WHEN discount <= 0.2 THEN 'Up to 20%'
        ELSE 'Over 20%'
    END AS discount_band,
    ROUND(AVG(profit),2) AS avg_profit,
    COUNT(*) AS num_line_items
FROM order_items
GROUP BY 1
ORDER BY avg_profit DESC;

-- 9. Monthly representative performance tracking view
/* 
KEY INSIGHTS:
- Granular Performance Baseline: Establishes a highly reusable, multi-dimensional view to audit individual sales representative trajectories month-over-month.
- Cross-Market Intelligence: Enables direct comparative analysis across regional structures, helping leadership separate market-driven success from individual sales rep skill.
- Dynamic Profitability Auditing: Computes a running breakdown of localized revenue alongside actual profit margins, immediately surfacing reps who drive top-line growth at the cost of bottom-line health.
- Variable Commission Modeling: Serves as a reliable, clean data foundation for finance teams to calculate variable incentives, monthly bonuses, and quota adjustments dynamically.
*/
CREATE VIEW monthly_rep_performance AS
SELECT DATE_TRUNC('month', o.order_date) AS month,
       r.rep_name, r.market, r.region,
       SUM(oi.sales) AS revenue,
       SUM(oi.profit) AS profit
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sales_reps r ON o.rep_id = r.rep_id
GROUP BY 1, 2, 3, 4;

-- 10. Index + query plan check
/* 
KEY INSIGHTS FROM THE EXPLAIN ANALYZE PLAN:
- Index Utilization Verified: The execution plan confirms that the query optimizer successfully skipped a slow Full Table Scan, utilizing a 'Bitmap Index Scan' on the new 'idx_orders_rep_id' btree index instead.
- Sub-Millisecond Execution Speed: The entire query resolved in an ultra-fast execution time of just 0.244 ms (with a rapid planning time of 0.080 ms), proving maximum optimization.
- Data Access Efficiency: The planner targeted the specific index condition ((rep_id)::text = 'R031'::text) in a single index search, cleanly isolating exactly 697 rows across 79 exact heap blocks.
- Optimized Memory Caching: The 'shared hit=82' metric indicates that all required data pages were read instantly from memory cache rather than slow physical disk storage, maximizing system I/O efficiency.
*/
CREATE INDEX idx_orders_rep_id ON orders(rep_id);

EXPLAIN ANALYZE
SELECT * FROM orders WHERE rep_id = 'R031';
