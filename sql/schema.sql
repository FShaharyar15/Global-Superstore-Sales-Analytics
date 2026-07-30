CREATE TABLE staging_orders (
    row_id INT,
    order_id VARCHAR(30),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(30),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    market VARCHAR(20),
    region VARCHAR(30),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales NUMERIC(10,2),
    unit_sold INT,
    unit_price NUMERIC(10,2),
    discount NUMERIC(4,2),
    profit NUMERIC(10,2),
    cogs NUMERIC(10,2),
    shipping_cost NUMERIC(10,2),
    order_priority VARCHAR(20),
    sales_rep_id VARCHAR(10)
);

CREATE TABLE sales_reps (
    rep_id VARCHAR(10) PRIMARY KEY,
    rep_name VARCHAR(100),
    region VARCHAR(30),
    market VARCHAR(20)
);

CREATE TABLE targets (
    rep_id VARCHAR(10) REFERENCES sales_reps(rep_id),
    month DATE,
    target_amount NUMERIC(10,2),
    PRIMARY KEY (rep_id, month)
);

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(30),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE products (
    product_id VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(50),
    sub_category VARCHAR(50)
);

CREATE TABLE orders (
    order_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES customers(customer_id),
    rep_id VARCHAR(10) REFERENCES sales_reps(rep_id),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    market VARCHAR(20),
    region VARCHAR(30),
    order_priority VARCHAR(20)
);

CREATE TABLE order_items (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(30) REFERENCES orders(order_id),
    product_id VARCHAR(30) REFERENCES products(product_id),
    sales NUMERIC(10,2),
    unit_sold INT,
    unit_price NUMERIC(10,2),
    discount NUMERIC(4,2),
    profit NUMERIC(10,2),
    cogs NUMERIC(10,2),
    shipping_cost NUMERIC(10,2)
);
