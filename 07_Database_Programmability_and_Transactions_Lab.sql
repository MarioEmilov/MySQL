-- 1
DELIMITER //
CREATE FUNCTION ufn_count_employees_by_town(town_name VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE emp_count INT; -- declare variable
    
    SET emp_count := (SELECT COUNT(*) FROM employees AS e
			JOIN addresses AS a
			ON e.address_id = a.address_id -- FK = PK
			JOIN towns AS t
			USING (town_id)
			WHERE t.name = town_name);
            
	RETURN emp_count;
END
//
DELIMITER ;
    
SELECT ufn_count_employees_in_city('Sofia');

-- 2
DELIMITER //
CREATE PROCEDURE usp_raise_salaries(IN department_name VARCHAR(50))
BEGIN
	UPDATE employees AS e JOIN departments AS d ON e.department_id = d.department_id 
    SET salary = salary * 1.05
    WHERE d.name = department_name;
END
//
DELIMITER ;

CALL usp_raise_salaries('Sales');

-- 3
DELIMITER //
CREATE PROCEDURE usp_raise_salary_by_id(IN emp_id INT)
BEGIN
	START TRANSACTION;
    IF((SELECT COUNT(*) FROM employees
    WHERE employee_id = emp_id) <> 1)
    THEN ROLLBACK;
    ELSE
		UPDATE employees
        SET salary = salary * 1.05
        WHERE employee_id = emp_id;
	END IF;
    COMMIT;
END
//
DELIMITER ;

CALL usp_raise_salary_by_id(268);

-- 4
CREATE TABLE deleted_employees(
	employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) DEFAULT NULL,
    job_title VARCHAR(50) NOT NULL,
    department_id INT(10) DEFAULT NULL,
    salary DECIMAL(19,4) NOT NULL
);

DROP TRIGGER IF EXISTS tr_deleted_employees;

DELIMITER //
CREATE TRIGGER tr_deleted_employees
AFTER DELETE -- When? - BEFORE /AFTER
ON employees -- Where it will be attached
FOR EACH ROW
BEGIN
	INSERT INTO deleted_employees (first_name, last_name, middle_name, job_title, department_id, salary)
    VALUES (OLD.first_name, OLD.last_name, OLD.middle_name, OLD.job_title, OLD.department_id, OLD.salary);
END
//
DELIMITER ;

DELETE FROM employees 
WHERE
    employee_id = 1;
