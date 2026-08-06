-- 1. Monthly revenue and profit trend
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(oi.sales) AS revenue,
       SUM(oi.profit) AS profit
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;

-- 2. Quota attainment by rep, most recent month in the data
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
SELECT order_date,
       SUM(daily_revenue) OVER (ORDER BY order_date) AS running_total
FROM (
    SELECT o.order_date, SUM(oi.sales) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
) daily;

-- 5. Revenue and margin by market
SELECT g.market,
       SUM(oi.sales) AS revenue,
       SUM(oi.profit) AS profit,
       ROUND(SUM(oi.profit) / NULLIF(SUM(oi.sales),0) * 100, 1) AS margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN geography g ON o.geography_id = g.geography_id
GROUP BY g.market
ORDER BY revenue DESC;

-- 6. Year-over-year growth by category
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
SELECT c.customer_name, SUM(oi.sales) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 8. Discount impact on profit margin
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

-- 9. Reusable view for the dashboard
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
CREATE INDEX idx_orders_rep_id ON orders(rep_id);

EXPLAIN ANALYZE
SELECT * FROM orders WHERE rep_id = 'R031';
