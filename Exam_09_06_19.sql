-- 1 -------------------------------------------------------
CREATE DATABASE ruk_database;
use ruk_database;

CREATE TABLE branches (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE employees (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    salary DECIMAL(10 , 2 ) NOT NULL,
    started_on DATE NOT NULL,
    branch_id INT(11) NOT NULL,
    CONSTRAINT fk_employess_branches FOREIGN KEY (branch_id)
        REFERENCES branches (id)
);

CREATE TABLE clients (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(50) NOT NULL,
    age INT(11) NOT NULL
);

CREATE TABLE bank_accounts (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    account_number VARCHAR(10) NOT NULL,
    balance DECIMAL(10 , 2 ) NOT NULL,
    client_id INT(11) NOT NULL UNIQUE,
    CONSTRAINT fk_bank_accounts_clients FOREIGN KEY (client_id)
        REFERENCES clients (id)
);

CREATE TABLE cards (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    card_number VARCHAR(19) NOT NULL,
    card_status VARCHAR(7) NOT NULL,
    bank_account_id INT(11) NOT NULL,
    CONSTRAINT fk_cards_bank_accounts FOREIGN KEY (bank_account_id)
        REFERENCES bank_accounts (id)
);

CREATE TABLE employees_clients (
    employee_id INT(11),
    client_id INT(11),
    CONSTRAINT fk_employees_clients_employees FOREIGN KEY (employee_id)
        REFERENCES employees (id),
    CONSTRAINT fk_employees_clients_clients FOREIGN KEY (client_id)
        REFERENCES clients (id)
);

-- 2 -------------------------------------------------------
INSERT INTO cards (card_number, card_status, bank_account_id)
	SELECT REVERSE(full_name) AS card_number, 
			'Active' AS card_status, 
            id AS bank_account_id  
	FROM clients
    WHERE id BETWEEN 191 AND 200;
    
-- 3 -------------------------------------------------------
UPDATE employees_clients AS ec
        JOIN
    (SELECT 
        ec2.employee_id, COUNT(ec2.client_id) AS 'clients_count'
    FROM
        employees_clients AS ec2
    GROUP BY ec2.employee_id
    ORDER BY clients_count , ec2.employee_id
    LIMIT 1) AS tbl 
SET 
    ec.employee_id = tbl.employee_id
WHERE
    ec.employee_id = ec.client_id;

-- -------------------------------------------------------

UPDATE employees_clients ec 
SET 
    ec.employee_id = (SELECT 
            tbl.employee_id
        FROM
            (SELECT 
                ec2.employee_id, COUNT(ec2.client_id) AS 'clients_count'
            FROM
                employees_clients ec2
            GROUP BY ec2.employee_id
            ORDER BY COUNT(ec2.client_id) , ec2.employee_id
            LIMIT 1) AS tbl)
WHERE
    ec.employee_id = ec.client_id;

-- --------------------------------------------------------

UPDATE employees_clients AS ec 
SET 
    ec.employee_id = (SELECT 
            tbl.employee_id
        FROM
            (SELECT 
                *
            FROM
                employees_clients) AS tbl
        GROUP BY employee_id
        ORDER BY COUNT(tbl.client_id) ASC , tbl.employee_id ASC
        LIMIT 1)
WHERE
    ec.employee_id = ec.client_id;

-- 4 -------------------------------------------------------
DELETE FROM employees 
WHERE
    id NOT IN (SELECT 
        employee_id
    FROM
        employees_clients);

-- -----------------------------------------
DELETE FROM employees 
WHERE
    id = (SELECT 
        emp.id
    FROM
        (SELECT 
            *
        FROM
            employees) AS emp
            LEFT JOIN
        employees_clients AS ec ON emp.id = ec.employee_id
    
    WHERE
        ec.client_id IS NULL
    LIMIT 1);

-- 5 -------------------------------------------------------
SELECT 
    id, full_name
FROM
    clients
ORDER BY id;

-- 6 -------------------------------------------------------
SELECT 
    id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    CONCAT('$', salary) AS salary,
    started_on
FROM
    employees
WHERE
    salary >= 100000
        AND started_on >= '2018-01-01'
ORDER BY salary DESC , id;

-- 7 -------------------------------------------------------
SELECT 
    ca.id,
    CONCAT(ca.card_number, ' : ', cl.full_name) AS card_token
FROM
    cards AS ca
        LEFT JOIN
    bank_accounts AS ba ON ca.bank_account_id = ba.id
        LEFT JOIN
    clients AS cl ON ba.client_id = cl.id
ORDER BY ca.id DESC;

-- 8 Do not submit in Judge -------------------------------------------------------
SELECT 
    ca.id,
    CONCAT(ca.card_number, ' : ', cl.full_name) AS card_token
FROM
    cards AS ca
        LEFT JOIN
    bank_accounts AS ba ON ca.bank_account_id = ba.id
        LEFT JOIN
    clients AS cl ON ba.client_id = cl.id
ORDER BY ca.id DESC;

-- ------------------------- Submit in Judge
SELECT 
    CONCAT(e.`first_name`, ' ', e.`last_name`) AS `full_name`,
    e.`started_on`,
    COUNT(ec.`client_id`) AS `count_of_clients`
FROM
    `employees` AS `e`
        JOIN
    `employees_clients` `ec` ON `e`.`id` = `ec`.`employee_id`
GROUP BY e.`id`
ORDER BY `count_of_clients` DESC , e.`id`
LIMIT 5;

-- 9 -------------------------------------------------------
SELECT 
    b.`name`, COUNT(c.`id`) AS `count_of_cards`
FROM
    `branches` AS `b`
        LEFT JOIN
    `employees` `e` ON `b`.`id` = `e`.`branch_id`
        LEFT JOIN
    `employees_clients` `ec` ON `e`.`id` = `ec`.`employee_id`
        LEFT JOIN
    `bank_accounts` `b2` ON `ec`.`client_id` = `b2`.`client_id`
        LEFT JOIN
    `cards` `c` ON `b2`.`id` = `c`.`bank_account_id`
GROUP BY b.`name`
ORDER BY `count_of_cards` DESC , b.`name`;

-- 10 -------------------------------------------------------

DELIMITER //
CREATE FUNCTION udf_client_cards_count(client_name VARCHAR(30))
RETURNS INT 
DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(ca.id) AS cards FROM clients AS cl
    LEFT JOIN bank_accounts AS ba
    ON cl.id = ba.client_id
    LEFT JOIN cards AS ca
    ON ba.id = ca.bank_account_id
    WHERE client_name = cl.full_name
    GROUP BY cl.full_name);

END 
//
DELIMITER ;

SELECT 
    c.full_name, UDF_CLIENT_CARDS_COUNT('Baxy David') AS `cards`
FROM
    clients c
WHERE
    c.full_name = 'Baxy David';

-- 11 -------------------------------------------------------
DROP PROCEDURE IF EXISTS udp_clientinfo;

DELIMITER //
CREATE PROCEDURE udp_clientinfo(IN client_name VARCHAR(50))
BEGIN
	SELECT cl.full_name, 
		cl.age, ba.account_number, 
        CONCAT('$', ba.balance) AS balance 
	FROM clients AS cl
    LEFT JOIN bank_accounts AS ba
    ON cl.id = ba.client_id
    WHERE cl.full_name = client_name;
END 
//

DELIMITER ;

CALL udp_clientinfo('Hunter Wesgate');