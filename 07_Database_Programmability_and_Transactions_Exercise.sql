-- 1 

DELIMITER //
CREATE PROCEDURE usp_get_employees_salary_above_35000()
BEGIN
	SELECT first_name, last_name 
    FROM employees
	WHERE salary > 35000
	ORDER BY first_name, last_name, employee_id;
END
//
DELIMITER ;

CALL usp_get_employees_salary_above_35000();

-- 2 

DELIMITER //
CREATE PROCEDURE usp_get_employees_salary_above (IN number DECIMAL(10,4))
BEGIN
	SELECT first_name, last_name 
    FROM employees
	WHERE salary >= number
	ORDER BY first_name, last_name, employee_id;
END 
//
DELIMITER ;

CALL usp_get_employees_salary_above(45000);

-- 3 

DELIMITER //
CREATE PROCEDURE usp_get_towns_starting_with(IN starts_with VARCHAR(50))
BEGIN
	SELECT name FROM towns
    WHERE name LIKE CONCAT(starts_with, '%')
    ORDER BY name;
END
//
DELIMITER ;

CALL usp_get_towns_starting_with('b');

-- 4 

DELIMITER //
CREATE PROCEDURE usp_get_employees_from_town(IN town_name VARCHAR(50))
BEGIN
	SELECT first_name, last_name FROM employees
    JOIN addresses
    USING(address_id)
    JOIN towns AS t
    USING(town_id)
    WHERE t.name = town_name
    ORDER BY first_name, last_name, employee_id;
END
//
DELIMITER ;

-- 5

DELIMITER //
CREATE FUNCTION ufn_get_salary_level(salary_emp DECIMAL(19,4))
RETURNS VARCHAR(10) DETERMINISTIC
BEGIN
	DECLARE result VARCHAR(10); -- declare variable
    SET result := 
		(CASE
			WHEN salary_emp < 30000 THEN 'Low'
			WHEN salary_emp BETWEEN 3000 AND 50000 THEN 'Average'
			ELSE 'High'
		END);
	RETURN result;
END
//
DELIMITER ;

SELECT UFN_GET_SALARY_LEVEL(13500.00);

CALL usp_get_employees_from_town('Sofia');

-- 6

DELIMITER $$
CREATE PROCEDURE usp_get_employees_by_salary_level(salary_level VARCHAR(7))
BEGIN
    SELECT e.first_name, e.last_name
    FROM `employees` AS e
    WHERE e.salary < 30000 AND salary_level = 'low'
        OR e.salary >= 30000 AND e.salary <= 50000 AND salary_level = 'average'
        OR e.salary > 50000 AND salary_level = 'high'
    ORDER BY e.first_name DESC, e.last_name DESC;
END 
$$
DELIMITER ;

CALL usp_get_employees_by_salary_level('high');

-- 7

DELIMITER //
CREATE FUNCTION ufn_is_word_comprised(set_of_letters varchar(50), word varchar(50))
RETURNS BIT DETERMINISTIC
BEGIN
	DECLARE result BIT;
    SET result := word REGEXP(CONCAT('(?i)^[', set_of_letters, ']+$')); 
    RETURN result;
END 
//
DELIMITER ;

SELECT UFN_IS_WORD_COMPRISED('oistmiahf', 'Sofia');
SELECT UFN_IS_WORD_COMPRISED('oistmiahf', 'halves');
SELECT UFN_IS_WORD_COMPRISED('bobr', 'Rob');
SELECT UFN_IS_WORD_COMPRISED('pppp', 'Guy');

-- 8

DELIMITER //
CREATE PROCEDURE usp_get_holders_full_name()
BEGIN
	SELECT CONCAT_WS(' ', first_name, last_name) AS full_name 
    FROM account_holders
    ORDER BY full_name, id;
END
//
DELIMITER ;

CALL usp_get_holders_full_name();

-- 9

DELIMITER //
CREATE PROCEDURE usp_get_holders_with_balance_higher_than(IN salary_level DECIMAL(19, 4))
BEGIN
	SELECT ah.first_name, ah.last_name FROM account_holders AS ah
    JOIN accounts AS a
    ON a.account_holder_id = ah.id
    GROUP BY a.account_holder_id
    HAVING SUM(a.balance) > salary_level
    ORDER BY ah.id;
END
//
DELIMITER ;

CALL usp_get_holders_with_balance_higher_than(7000);

-- 10

DELIMITER //
CREATE FUNCTION ufn_calculate_future_value(initial_sum DECIMAL(19,4), interest_rate DOUBLE, years INT)
RETURNS DECIMAL(19,4)
DETERMINISTIC
BEGIN
	DECLARE result DECIMAL(19,4); -- declare variable
    SET result := 
		initial_sum * POW((1 + interest_rate), years);
	RETURN result;
END
//
DELIMITER ;

SELECT UFN_CALCULATE_FUTURE_VALUE(1000, 0.5, 5);

-- 11

DELIMITER //
CREATE FUNCTION ufn_calculate_future_value(initial_sum DECIMAL (19,4), interest_rate DECIMAL (19, 4), years INT)
RETURNS DECIMAL (19, 4)
BEGIN
	RETURN initial_sum * pow((1 + interest_rate), years);
    END
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE usp_calculate_future_value_for_account(account_id INT, interest_rate DECIMAL (19, 4))
BEGIN
SELECT a.id AS 'account_id',
	ah.first_name,
    ah.last_name,
    a.balance AS 'current_balance',
    ufn_calculate_future_value (a.balance, interest_rate, 5) AS 'balance_in_5_years'
FROM account_holders AS ah 
JOIN 
accounts AS a ON ah.id = a.account_holder_id
WHERE a.id = account_id;
END //
DELIMITER ;
CALL usp_calculate_future_value_for_account(1, 0.1);

-- 12

DELIMITER //
CREATE PROCEDURE usp_deposit_money(account_id INT, money_amount DECIMAL(19,4))
BEGIN
	START TRANSACTION; 
    IF(money_amount <= 0) 
		THEN ROLLBACK;
    ELSE
		UPDATE accounts
        SET balance = balance + money_amount
        WHERE id = account_id;
        END IF;
        COMMIT;
END 
//
DELIMITER ;

CALL usp_deposit_money(1, 100);

-- 13

DELIMITER //
CREATE PROCEDURE usp_withdraw_money(account_id INT, money_amount DECIMAL(19,4))
BEGIN
	START TRANSACTION; 
    IF(money_amount <= 0) OR
		money_amount > (SELECT balance FROM accounts WHERE id = account_id)
		THEN ROLLBACK;
    ELSE
		UPDATE accounts
        SET balance = balance - money_amount
        WHERE id = account_id;
        END IF;
        COMMIT;
END 
//
DELIMITER ;

CALL usp_withdraw_money(1, 100);

-- 14

DELIMITER //
CREATE PROCEDURE usp_transfer_money(from_account_id INT, to_account_id INT, amount DECIMAL(19,4))
BEGIN
	START TRANSACTION; 
    IF(from_account_id = to_account_id) OR
		(SELECT id FROM accounts WHERE id = to_account_id) IS NULL OR
        (SELECT id FROM accounts WHERE id = from_account_id) IS NULL OR
        (SELECT balance FROM accounts WHERE id = from_account_id) < amount OR
		(amount <= 0)
		THEN ROLLBACK;
    ELSE
		UPDATE accounts
        SET balance = balance - amount
        WHERE id = from_account_id;
        UPDATE accounts
        SET balance = balance + amount
        WHERE id = to_account_id;
        END IF;
        COMMIT;
END 
//
DELIMITER ;

CALL usp_transfer_money(1, 2, 10);

-- 15

CREATE TABLE `logs` (
    log_id INT(11) PRIMARY KEY AUTO_INCREMENT,
    account_id INT(11) NOT NULL,
    old_sum DECIMAL(19 , 4 ) NOT NULL,
    new_sum DECIMAL(19 , 4 ) NOT NULL,
    CONSTRAINT fk_logs_accounts FOREIGN KEY (account_id)
        REFERENCES accounts (id)
);

DROP TRIGGER IF EXISTS tr_balance_updated;

DELIMITER //
CREATE TRIGGER tr_balance_updated
AFTER UPDATE -- When? - BEFORE /AFTER Event? -UPDATE /DELETE/ INSERT
ON accounts -- Where it will be attached
FOR EACH ROW
BEGIN
	IF OLD.balance <> NEW.balance THEN
		INSERT INTO `logs` (account_id, old_sum, new_sum)
		VALUES (OLD.id, OLD.balance, NEW.balance);
    END IF;
END
//
DELIMITER ;

CALL usp_transfer_money(2, 1, 100);
CALL usp_transfer_money(1, 2, 10);

SELECT 
    *
FROM
    `logs`;

-- 16

CREATE TABLE `notification_emails` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `recipient` INT NOT NULL,
    `subject` VARCHAR(60) NOT NULL,
    `body` VARCHAR(255) NOT NULL
);

DROP TRIGGER IF EXISTS tr_notification_emails;

DELIMITER //
CREATE TRIGGER tr_notification_emails
AFTER INSERT ON `logs` 
FOR EACH ROW
BEGIN
	INSERT INTO `notification_emails`(`recipient`, `subject`, `body`)
	VALUES (NEW.account_id, 
		CONCAT('Balance change for account: ', NEW.account_id), 
		CONCAT('On ', DATE_FORMAT(NOW(), '%b %d %Y at %r'), ' your balance was changed from ', 
			ROUND(NEW.old_sum, 2), ' to ', ROUND(NEW.new_sum, 2), '.'));
END
//
DELIMITER ;

SELECT 
    *
FROM
    `notification_emails`;