INSERT INTO customers (customer_id, customer_name, segment, city, state, country)
SELECT DISTINCT ON (customer_id) customer_id, customer_name, segment, city, state, country
FROM staging_orders
ORDER BY customer_id;

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT DISTINCT ON (product_id) product_id, product_name, category, "sub-category"
FROM staging_orders
ORDER BY product_id;

INSERT INTO orders (order_id, customer_id, rep_id, order_date, ship_date, ship_mode, market, region, order_priority)
SELECT DISTINCT ON (order_id) order_id, customer_id, sales_rep_id, order_date, ship_date, ship_mode, market, region, order_priority
FROM staging_orders
ORDER BY order_id;

INSERT INTO order_items (row_id, order_id, product_id, sales, unit_sold, unit_price, discount, profit, cogs, shipping_cost)
SELECT row_id, order_id, product_id, sales, unit_sold, unit_price, discount, profit, cogs, shipping_cost
FROM staging_orders;
