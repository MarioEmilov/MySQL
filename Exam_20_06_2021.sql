-- 1
CREATE DATABASE taxi;

CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(10) NOT NULL
);

CREATE TABLE cars (
    id INT PRIMARY KEY AUTO_INCREMENT,
    make VARCHAR(20) NOT NULL,
    model VARCHAR(20),
    `year` INT NOT NULL DEFAULT 0,
    mileage INT DEFAULT 0,
    `condition` CHAR(1) NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_cars_categories FOREIGN KEY (category_id)
        REFERENCES categories (id)
);

CREATE TABLE drivers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    age INT NOT NULL,
    rating FLOAT DEFAULT 5.5
);

CREATE TABLE cars_drivers (
    car_id INT NOT NULL,
    driver_id INT NOT NULL,
    CONSTRAINT pk_cars_drivers PRIMARY KEY (car_id , driver_id),
    CONSTRAINT fk_cars_drivers_cars FOREIGN KEY (car_id)
        REFERENCES cars (id),
    CONSTRAINT fk_cars_drivers_drivers FOREIGN KEY (driver_id)
        REFERENCES drivers (id)
);

CREATE TABLE addresses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL
);

CREATE TABLE clients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL
);

CREATE TABLE courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    from_address_id INT NOT NULL,
    `start` DATETIME NOT NULL,
    car_id INT NOT NULL,
    client_id INT NOT NULL,
    bill DECIMAL(10 , 2 ) DEFAULT 10,
    CONSTRAINT fk_courses_addresses FOREIGN KEY (from_address_id)
        REFERENCES addresses (id),
    CONSTRAINT fk_courses_cars FOREIGN KEY (car_id)
        REFERENCES cars (id),
    CONSTRAINT fk_courses_client FOREIGN KEY (client_id)
        REFERENCES clients (id)
);

-- 2
INSERT INTO clients (full_name, phone_number)
SELECT  
CONCAT_WS(' ', first_name, last_name) AS full_name,
CONCAT('(088) 9999', (id * 2)) AS phone_number
FROM drivers
WHERE id BETWEEN 10 AND 20;

-- 3
UPDATE cars 
SET 
    `condition` = 'C'
WHERE
    (`mileage` >= 80000 OR `mileage` IS NULL)
        AND `year` <= 2010
        AND make NOT LIKE 'Mercedes-Benz';

-- 4
DELETE FROM clients 
WHERE
    id NOT IN (SELECT 
        client_id
    FROM
        courses)
    AND CHAR_LENGTH(full_name) > 3;

-- 5
SELECT 
    make, model, `condition`
FROM
    cars
ORDER BY id;

-- 6
SELECT 
    d.first_name, d.last_name, c.make, c.model, c.mileage
FROM
    drivers d
        JOIN
    cars_drivers cd ON cd.driver_id = d.id
        JOIN
    cars c ON cd.car_id = c.id
WHERE
    c.mileage != 0
ORDER BY c.mileage DESC , d.first_name;

-- 7
SELECT 
    c.id,
    c.make,
    c.mileage,
    COUNT(co.id) AS 'count_of_courses',
    ROUND(AVG(co.bill), 2) AS 'avg_bill'
FROM
    cars c
        LEFT JOIN
    courses co ON co.car_id = c.id
GROUP BY c.id
HAVING count_of_courses != 2
ORDER BY count_of_courses DESC , c.id;

-- 8
SELECT 
    cl.`full_name`,
    COUNT(co.`car_id`) AS `count_of_cars`,
    SUM(co.`bill`) AS `total_sum`
FROM
    `clients` AS cl
        JOIN
    `courses` AS co ON cl.`id` = co.`client_id`
WHERE
    cl.`full_name` LIKE '_a%'
GROUP BY cl.`full_name`
HAVING `count_of_cars` > 1
ORDER BY cl.`full_name`;

-- 9
SELECT 
    a.name,
    IF(HOUR(c.`start`) BETWEEN 6 AND 20,
        'Day',
        'Night') AS 'day_time',
    c.bill,
    cl.full_name,
    cr.make,
    cr.model,
    ct.name
FROM
    courses c
        JOIN
    addresses a ON c.from_address_id = a.id
        JOIN
    clients cl ON c.client_id = cl.id
        JOIN
    cars cr ON c.car_id = cr.id
        JOIN
    categories ct ON cr.category_id = ct.id
ORDER BY c.id;

-- 10
DELIMITER //
CREATE FUNCTION udf_courses_by_client(phone_num VARCHAR (20))
RETURNS INT DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(cor.id) FROM courses AS cor
			LEFT JOIN clients AS cl
			ON cor.client_id = cl.id
            WHERE cl.phone_number = phone_num
			GROUP BY cl.id);
END 
//
DELIMITER ;

-- 11
DELIMITER //
CREATE PROCEDURE udp_courses_by_address(address_name VARCHAR(100))
BEGIN
	SELECT a.`name`, 
			cl.full_name AS full_names,
			(CASE
				WHEN cor.bill <= 20 THEN 'Low'
				WHEN cor.bill <= 30 THEN 'Medium'
				WHEN cor.bill > 30 THEN 'High'
			END) AS level_of_bill,
			c.`make`,
			c.`condition`,
			cat.`name` AS cat_name
	FROM addresses AS a
	LEFT JOIN courses AS cor
	ON cor.from_address_id = a.id
	LEFT JOIN clients AS cl
	ON cor.client_id = cl.id
	LEFT JOIN cars AS c
	ON cor.car_id = c.id 
	LEFT JOIN categories AS cat
	ON c.category_id = cat.id
	WHERE a.name = address_name
	ORDER BY c.`make`, cl.full_name;
END 
//
DELIMITER ;
