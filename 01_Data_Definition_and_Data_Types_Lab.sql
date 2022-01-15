#Exercise 01 Create Tables
CREATE TABLE `minions` (
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(50),
    `age` INT 
);

CREATE TABLE `towns` (
	`town_id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(50)
);

#Exercise 02 Insert Data in Tables
INSERT INTO `employees` (`first_name`, `last_name`)
VALUES 
('Test', 'Test'),
('Test1', 'Test1'),
('Test2', 'Test2');
   
# Exercise 03 Alter Table 
ALTER TABLE `employees` 
ADD COLUMN `middle_name` VARCHAR(45);  

# Exercise 04 Adding Constraint
ALTER TABLE `products`
ADD CONSTRAINT fk_products_categories
FOREIGN KEY `products`(`category_id`)
REFERENCES `categories`(`id`);

# Exercise 05 Modifying Columns
ALTER TABLE `employees`
CHANGE COLUMN `middle_name` `middle_name` VARCHAR(100);