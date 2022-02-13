-- 1
CREATE DATABASE online_stores;

CREATE TABLE customers (
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(20) NOT NULL,
last_name VARCHAR(20) NOT NULL,
phone VARCHAR(30) NOT NULL UNIQUE,
address VARCHAR(60) NOT NULL,
discount_card BIT(1) NOT NULL DEFAULT (FALSE)
);

CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_datetime DATETIME NOT NULL,
    customer_id INT NOT NULL,
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id)
        REFERENCES customers (id)
);

CREATE TABLE reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    content TEXT,
    rating DECIMAL(10 , 2 ) NOT NULL,
    picture_url VARCHAR(80) NOT NULL,
    published_at DATETIME NOT NULL
);

CREATE TABLE brands (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(40) NOT NULL,
    price DECIMAL(19 , 2 ) NOT NULL,
    quantity_in_stock INT,
    `description` TEXT,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    review_id INT,
    CONSTRAINT fk_products_brand FOREIGN KEY (brand_id)
        REFERENCES brands (id),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES categories (id),
    CONSTRAINT fk_products_review FOREIGN KEY (review_id)
        REFERENCES reviews (id)
);

CREATE TABLE orders_products (
    order_id INT,
    product_id INT,
    CONSTRAINT fk_orders_products_orders FOREIGN KEY (order_id)
        REFERENCES orders (id),
    CONSTRAINT fk_orders_products_products FOREIGN KEY (product_id)
        REFERENCES products (id)
);

-- 2
INSERT INTO reviews (content, picture_url, published_at, rating)
SELECT LEFT(p.`description`, 15), REVERSE(p.`name`), '2010-10-10', p.price / 8
FROM products AS p
WHERE p.id >= 5;

-- 3
UPDATE products 
SET 
    quantity_in_stock = quantity_in_stock - 5
WHERE
    quantity_in_stock BETWEEN 60 AND 70;

-- 4 
DELETE FROM customers 
WHERE
    id NOT IN (SELECT 
        customer_id
    FROM
        orders);

-- 5
SELECT 
    id, `name`
FROM
    categories
ORDER BY `name` DESC;

-- 6
SELECT 
    id, brand_id, `name`, quantity_in_stock
FROM
    products
WHERE
    price > 1000 AND quantity_in_stock < 30
ORDER BY quantity_in_stock , id;

-- 7
SELECT 
    *
FROM
    reviews
WHERE
    content LIKE 'My%'
        AND CHAR_LENGTH(content) > 61
ORDER BY rating DESC;

-- 8
SELECT 
    CONCAT_WS(' ', c.first_name, c.last_name) AS full_name,
    c.address,
    o.order_datetime
FROM
    customers c
        JOIN
    orders o ON o.customer_id = c.id
WHERE
    YEAR(order_datetime) <= 2018
ORDER BY full_name DESC;

-- 9
SELECT 
    COUNT(c.id) AS items_count,
    c.`name`,
    SUM(p.quantity_in_stock) AS total_quantity
FROM
    categories AS c
        JOIN
    products AS p ON c.id = p.category_id
GROUP BY c.id
ORDER BY items_count DESC , total_quantity ASC
LIMIT 5;

-- 10
DROP FUNCTION IF EXISTS udf_customer_products_count;
DELIMITER //
CREATE FUNCTION udf_customer_products_count(`name` VARCHAR(30))
RETURNS INT 
DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(c.first_name) FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN orders_products op ON o.id = op.order_id
    GROUP BY c.first_name
    HAVING c.first_name = `name`);
END 
//
DELIMITER ;

SELECT 
    c.first_name,
    c.last_name,
    UDF_CUSTOMER_PRODUCTS_COUNT('Shirley') AS `total_products`
FROM
    customers c
WHERE
    c.first_name = 'Shirley';

-- 11
DROP PROCEDURE IF EXISTS udp_reduce_price;
DELIMITER //
CREATE PROCEDURE udp_reduce_price(category_name VARCHAR(50))
BEGIN
UPDATE products p
	JOIN reviews r ON p.review_id = r.id
    JOIN categories c ON p.category_id = c.id
    SET price = price * 0.70
	WHERE rating < 4 AND 
    c.`name` = category_name;    
END
//
DELIMITER ;
CALL udp_reduce_price ('Phones and tablets');
