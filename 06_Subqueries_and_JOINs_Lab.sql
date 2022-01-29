-- 1 Managers

SELECT 
    e.`employee_id` AS 'id',
    CONCAT(e.`first_name`, ' ', e.`Last_name`) AS 'full_name',
    d.`department_id`,
    d.`name` AS `department_name`
FROM
    `departments` AS d
        JOIN
    `employees` AS e ON d.`manager_id` = e.`employee_id`
ORDER BY e.`employee_id`
LIMIT 5;

-- 2 Towns and Addresses

SELECT 
    a.`town_id`, t.`name` AS 'town_name', a.`address_text`
FROM
    `addresses` AS a,
    `towns` AS t
WHERE
    a.`town_id` = t.`town_id`
        AND t.`name` IN ('San Francisco' , 'Sofia', 'Carnation')
ORDER BY a.`town_id` , a.`address_id`;


SELECT 
    a.`town_id`, t.`name` AS 'town_name', a.`address_text`
FROM
    `addresses` AS a
        JOIN
    `towns` AS t ON a.`town_id` = t.`town_id`
        AND t.`name` IN ('San Francisco' , 'Sofia', 'Carnation')
ORDER BY a.`town_id` , a.`address_id`;

-- 3 Employees Without Managers 

SELECT 
    e.`employee_id`,
    e.`first_name`,
    e.`last_name`,
    d.`department_id`,
    e.`salary`
FROM
    `employees` AS e
        JOIN
    `departments` AS d ON e.`department_id` = d.`department_id`
WHERE
    e.`manager_id` IS NULL;
    
-- 4 High Salary

SELECT 
    COUNT(`employee_id`) AS `average_salary`
FROM
    `employees`
WHERE
    `salary` > (SELECT 
            AVG(`salary`)
        FROM
            `employees`);