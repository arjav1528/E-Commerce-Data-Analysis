-- Olist Brazilian E-Commerce schema
-- Load order: customers, sellers, products, category_translation, geolocation,
--             orders, order_items, payments, reviews

DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;
DROP TABLE IF EXISTS category_translation CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id              VARCHAR(64) PRIMARY KEY,
    customer_unique_id       VARCHAR(64) NOT NULL,
    customer_zip_code_prefix VARCHAR(16),
    customer_city            VARCHAR(128),
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(64) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(16),
    seller_city            VARCHAR(128),
    seller_state           CHAR(2)
);

CREATE TABLE products (
    product_id                 VARCHAR(64) PRIMARY KEY,
    product_category_name      VARCHAR(128),
    product_name_lenght        INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(128) PRIMARY KEY,
    product_category_name_english VARCHAR(128)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(16),
    geolocation_lat             DOUBLE PRECISION,
    geolocation_lng             DOUBLE PRECISION,
    geolocation_city            VARCHAR(128),
    geolocation_state           CHAR(2)
);

CREATE TABLE orders (
    order_id                      VARCHAR(64) PRIMARY KEY,
    customer_id                   VARCHAR(64) NOT NULL REFERENCES customers(customer_id),
    order_status                  VARCHAR(32),
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id            VARCHAR(64) NOT NULL REFERENCES orders(order_id),
    order_item_id       INTEGER     NOT NULL,
    product_id          VARCHAR(64) NOT NULL REFERENCES products(product_id),
    seller_id           VARCHAR(64) NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(12,2),
    freight_value       NUMERIC(12,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE payments (
    order_id             VARCHAR(64) NOT NULL REFERENCES orders(order_id),
    payment_sequential   INTEGER     NOT NULL,
    payment_type         VARCHAR(32),
    payment_installments INTEGER,
    payment_value        NUMERIC(12,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE reviews (
    review_id              VARCHAR(64),
    order_id               VARCHAR(64) NOT NULL REFERENCES orders(order_id),
    review_score           SMALLINT,
    review_comment_title   TEXT,
    review_comment_message TEXT,
    review_creation_date   TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

CREATE INDEX idx_orders_customer        ON orders(customer_id);
CREATE INDEX idx_orders_purchase_ts     ON orders(order_purchase_timestamp);
CREATE INDEX idx_orders_status          ON orders(order_status);
CREATE INDEX idx_order_items_product    ON order_items(product_id);
CREATE INDEX idx_order_items_seller     ON order_items(seller_id);
CREATE INDEX idx_payments_order         ON payments(order_id);
CREATE INDEX idx_reviews_order          ON reviews(order_id);
CREATE INDEX idx_products_category      ON products(product_category_name);
CREATE INDEX idx_geolocation_zip        ON geolocation(geolocation_zip_code_prefix);
