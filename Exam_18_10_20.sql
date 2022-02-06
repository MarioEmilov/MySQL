-- 1 -------------------------------------------
CREATE DATABASE softUniStoresSystem;

CREATE TABLE towns (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE addresses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    town_id INT NOT NULL,
    CONSTRAINT fk_addresses_towns FOREIGN KEY (town_id)
        REFERENCES towns (id)
);

CREATE TABLE stores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    rating FLOAT NOT NULL,
    has_parking TINYINT(1) DEFAULT 0,
    address_id INT NOT NULL,
    CONSTRAINT fk_stores_addresses FOREIGN KEY (address_id)
        REFERENCES addresses (id)
);

CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(15) NOT NULL,
    middle_name CHAR(1),
    last_name VARCHAR(20) NOT NULL,
    salary DECIMAL(19 , 2 ) NOT NULL DEFAULT 0,
    hire_date DATE NOT NULL,
    manager_id INT,
    CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id)
        REFERENCES employees (id),
    store_id INT NOT NULL,
    CONSTRAINT fk_employees_stores FOREIGN KEY (store_id)
        REFERENCES stores (id)
);

CREATE TABLE pictures (
    id INT PRIMARY KEY AUTO_INCREMENT,
    url VARCHAR(100) NOT NULL,
    added_on DATETIME NOT NULL
);

CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(40) NOT NULL UNIQUE,
    best_before DATE,
    price DECIMAL(10 , 2 ) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (category_id)
        REFERENCES categories (id),
    picture_id INT NOT NULL,
    CONSTRAINT fk_products_pictures FOREIGN KEY (picture_id)
        REFERENCES pictures (id)
);

CREATE TABLE products_stores (
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    CONSTRAINT pk_products_stores PRIMARY KEY (product_id , store_id),
    CONSTRAINT fk_products_stores_products FOREIGN KEY (product_id)
        REFERENCES products (id),
    CONSTRAINT fk_products_stores_stores FOREIGN KEY (store_id)
        REFERENCES stores (id)
);

-- 2 -------------------------------------------

INSERT INTO products_stores(product_id, store_id)
	SELECT id AS product_id, 1 AS store_id
    FROM products
    WHERE id NOT IN (SELECT product_id FROM products_stores);
    
-- 3 -------------------------------------------

UPDATE employees AS e 
SET 
    e.salary = e.salary - 500,
    e.manager_id = 3
WHERE
    YEAR(e.hire_date) > 2003
        AND e.store_id NOT IN (SELECT 
            s.id
        FROM
            stores AS s
        WHERE
            s.name IN ('Cardguard' , 'Veribet'));

-- -------------------------------------------------------------------------------------------

UPDATE employees AS e
        JOIN
    stores AS s ON e.store_id = s.id 
SET 
    e.salary = e.salary - 500,
    e.manager_id = 3
WHERE
    YEAR(e.hire_date) > 2003
        AND s.name NOT IN ('Cardguard' , 'Veribet');
    
-- 4 -------------------------------------------

DELETE FROM employees 
WHERE
    salary >= 6000
    AND manager_id IS NOT NULL;

-- 5 -------------------------------------------

SELECT 
    first_name, middle_name, last_name, salary, hire_date
FROM
    employees
ORDER BY hire_date DESC;

-- 6 -------------------------------------------

SELECT 
    p.name AS product_name,
    p.price,
    p.best_before,
    CONCAT(LEFT(p.description, 10), '...') AS short_description,
    pic.url
FROM
    products AS p
        JOIN
    pictures AS pic ON p.picture_id = pic.id
WHERE
    CHAR_LENGTH(p.description) > 100
        AND YEAR(pic.added_on) < 2019
        AND p.price > 20
ORDER BY p.price DESC;

-- 7 -------------------------------------------

SELECT 
    s.name,
    COUNT(p.id) AS product_count,
    ROUND(AVG(p.price), 2) AS avg
FROM
    stores AS s
        LEFT JOIN
    products_stores AS ps ON s.id = ps.store_id
        LEFT JOIN
    products AS p ON p.id = ps.product_id
GROUP BY s.name
ORDER BY product_count DESC , avg DESC , s.id;

-- 8 -------------------------------------------

SELECT 
    CONCAT_WS(' ', e.first_name, e.last_name) AS Full_name,
    s.name AS Store_name,
    a.name,
    e.salary
FROM
    employees AS e
        JOIN
    stores AS s ON e.store_id = s.id
        JOIN
    addresses AS a ON s.address_id = a.id
WHERE
    e.salary < 4000 AND a.name LIKE '%5%'
        AND CHAR_LENGTH(s.name) > 8
        AND e.last_name LIKE '%n';
        
-- 9 -------------------------------------------

SELECT 
    REVERSE(s.name) AS reverse_name,
    CONCAT(UPPER(t.name), '-', a.name) AS full_address,
    COUNT(e.id) AS employees_count
FROM
    stores AS s
        LEFT JOIN
    addresses AS a ON s.address_id = a.id
        LEFT JOIN
    towns AS t ON a.town_id = t.id
        LEFT JOIN
    employees AS e ON s.id = e.store_id
GROUP BY s.id
HAVING employees_count >= 1
ORDER BY full_address;

-- ------------------------------------------------------------- Judge don't work

SELECT 
    REVERSE(s.name) AS reverse_name,
    CONCAT(UPPER(t.name), '-', a.name) AS full_address,
    (SELECT 
            COUNT(e.id)
        FROM
            employees AS e
        WHERE
            e.store_id = s.id) AS employees_count
FROM
    stores AS s
        JOIN
    addresses AS a ON s.address_id = a.id
WHERE
    (SELECT 
            COUNT(e.id)
        FROM
            employees AS e
        WHERE
            e.store_id = s.id) > 0
ORDER BY full_address;

-- 10 -------------------------------------------

DROP FUNCTION IF EXISTS udf_top_paid_employee_by_store;

DELIMITER //
CREATE FUNCTION udf_top_paid_employee_by_store(store_name VARCHAR(50))
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	RETURN (SELECT 
				CONCAT(e.first_name, ' ', middle_name, '. ', last_name,
				' works in store for ',
				FLOOR(DATEDIFF('2020-10-18', hire_date) / 365.25),  # 2020 - YEAR(hire_date),
				' years') AS full_info
			FROM
			employees AS e
			JOIN
			stores AS s 
			ON e.store_id = s.id
			WHERE s.name = store_name
			ORDER by salary DESC
			LIMIT 1);
END 
//
DELIMITER ;

SELECT UDF_TOP_PAID_EMPLOYEE_BY_STORE('Stronghold') AS 'full_info';
SELECT UDF_TOP_PAID_EMPLOYEE_BY_STORE('Keylex') AS 'full_info';

-- 11 -------------------------------------------

DROP PROCEDURE IF EXISTS udp_update_product_price;

DELIMITER //
CREATE PROCEDURE udp_update_product_price (address_name VARCHAR (50))
BEGIN
    	DECLARE increase_level INT;
    
    	IF address_name LIKE '0%' THEN SET increase_level = 100;
    	ELSE SET increase_level = 200;
	    END IF;
    
    	UPDATE products AS p
    	SET price = price + increase_level
    	WHERE p.id IN (SELECT ps.product_id FROM addresses AS a
		    JOIN stores AS s ON a.id = s.address_id
                    JOIN products_stores AS ps ON ps.store_id = s.id
                    WHERE a.name = address_name
                    );
END 
//
DELIMITER ;

-- ----------------------------------------------------------------------
        
DELIMITER //
CREATE PROCEDURE udp_update_product_price (address_name VARCHAR (50))
BEGIN  
	DECLARE increase_level INT;
    	CASE LEFT(address_name, 1)
		WHEN '0' THEN SET increase_level := 100;
		ELSE SET increase_level := 200;
	END CASE;
	
	UPDATE products AS p
	JOIN products_stores  AS ps
		ON p.id = ps.product_id
	JOIN stores AS s
		ON s.id = ps.store_id
	JOIN addresses AS a
		ON a.id = s.address_id
	SET price = price + increase_level
	WHERE a.name = address_name;
END 
//
DELIMITER ;

-- ----------------------------------------------------------------------
        
DELIMITER //
CREATE PROCEDURE udp_update_product_price (address_name VARCHAR (50))
BEGIN   
	UPDATE products AS p
	JOIN products_stores  AS ps
		ON p.id = ps.product_id
	JOIN stores AS s
		ON s.id = ps.store_id
	JOIN addresses AS a
		ON a.id = s.address_id
	SET price = (
	    CASE LEFT(address_name, 1)
		WHEN '0' THEN price + 100
		ELSE price + 200
	    END)
	WHERE a.name = address_name;
END 
//
DELIMITER ;

CALL udp_update_product_price('07 Armistice Parkway');
SELECT 
    name, price
FROM
    products
WHERE
    id = 15;

CALL udp_update_product_price('1 Cody Pass');
SELECT 
    name, price
FROM
    products
WHERE
    id = 17;