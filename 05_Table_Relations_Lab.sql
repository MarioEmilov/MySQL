-- 1 Mountains and Peaks
CREATE TABLE `mountains` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(45)
);

CREATE TABLE `peaks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(45),
    `mountain_id` INT,
    CONSTRAINT `fk_peaks_mountains` FOREIGN KEY (`mountain_id`)
        REFERENCES `mountains` (`id`)
);

-- 2 Trip Organization
SELECT 
    v.driver_id,
    v.vehicle_type,
    CONCAT(c.first_name, ' ', c.last_name) AS driver_name
FROM
    campers AS c
        JOIN
    vehicles AS v ON v.driver_id = c.id;

-- 3 SoftUni Hiking
SELECT 
    `starting_point` AS `route_starting_point`,
    `end_point` AS `route_ending_point`,
    `leader_id`,
    CONCAT(c.`first_name`, ' ', c.`last_name`) AS `leader_name`
FROM
    `routes` AS r
        JOIN
    `campers` AS c ON r.`leader_id` = c.`id`;

-- 4 Delete Mountains
DROP TABLE peaks;
DROP TABLE mountains;

CREATE TABLE `mountains` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(45)
);

CREATE TABLE `peaks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(45),
    `mountain_id` INT,
    CONSTRAINT `fk_peaks_mountains` FOREIGN KEY (`mountain_id`)
        REFERENCES `mountains` (`id`)
        ON DELETE CASCADE
);
