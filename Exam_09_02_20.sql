-- 1 ------------------------------------------------------

CREATE DATABASE fsd;
USE fsd;

CREATE TABLE countries (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL
);

CREATE TABLE towns (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL,
    country_id INT(11) NOT NULL,
    CONSTRAINT fk_towns_countries FOREIGN KEY (country_id)
        REFERENCES countries (id)
);

CREATE TABLE stadiums (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL,
    capacity INT(11) NOT NULL,
    town_id INT(11) NOT NULL,
    CONSTRAINT fk_stadiums_towns FOREIGN KEY (town_id)
        REFERENCES towns (id)
);

CREATE TABLE teams (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL,
    established DATE NOT NULL,
    fan_base BIGINT(20) NOT NULL DEFAULT 0,
    stadium_id INT(11) NOT NULL,
    CONSTRAINT fk_teams_stadiums FOREIGN KEY (stadium_id)
        REFERENCES stadiums (id)
);

CREATE TABLE skills_data (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    dribbling INT(11) DEFAULT 0,
    pace INT(11) DEFAULT 0,
    passing INT(11) DEFAULT 0,
    shooting INT(11) DEFAULT 0,
    speed INT(11) DEFAULT 0,
    strength INT(11) DEFAULT 0
);

CREATE TABLE players (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(10) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    age INT(11) NOT NULL DEFAULT 0,
    position CHAR(1) NOT NULL,
    salary DECIMAL(10 , 2 ) NOT NULL DEFAULT 0,
    hire_date DATETIME,
    skills_data_id INT(11) NOT NULL,
    CONSTRAINT fk_players_skills_data FOREIGN KEY (skills_data_id)
        REFERENCES skills_data (id),
    team_id INT(11),
    CONSTRAINT fk_players_teams FOREIGN KEY (team_id)
        REFERENCES teams (id)
);

CREATE TABLE coaches (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(10) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    salary DECIMAL(10 , 2 ) NOT NULL DEFAULT 0,
    coach_level INT(11) NOT NULL DEFAULT 0
);

CREATE TABLE players_coaches (
    player_id INT(11),
    coach_id INT(11),
    CONSTRAINT pk_players_coaches PRIMARY KEY (player_id , coach_id),
    CONSTRAINT fk_players_coaches_players FOREIGN KEY (player_id)
        REFERENCES players (id),
    CONSTRAINT fk_players_coachess_coaches FOREIGN KEY (coach_id)
        REFERENCES coaches (id)
);

-- 2 ------------------------------------------------------

INSERT INTO coaches(first_name, last_name, salary, coach_level)
	SELECT 
		first_name, 
		last_name, 
        salary * 2, 
        CHAR_LENGTH(first_name) AS coach_level
    FROM players 
    WHERE age >= 45;
    
-- 3 ------------------------------------------------------

UPDATE coaches 
SET 
    coach_level = coach_level + 1
WHERE
    first_name LIKE 'A%'
        AND (SELECT 
            COUNT(*)
        FROM
            players_coaches
        WHERE
            coach_id = id);
-- ---------------------------------------------
UPDATE coaches AS c
        JOIN
    players_coaches AS pk ON pk.coach_id = c.id 
SET 
    `coach_level` = `coach_level` + 1
WHERE
    first_name LIKE 'A%';
    
-- 4 ------------------------------------------------------

DELETE FROM players 
WHERE
    age >= 45; 

-- 5 ------------------------------------------------------

DROP DATABASE fsd;
CREATE DATABASE fsd;

SELECT 
    first_name, age, salary
FROM
    players
ORDER BY salary DESC;

-- 6 ------------------------------------------------------

SELECT 
    p.id,
    CONCAT_WS(' ', p.first_name, p.last_name) AS full_name,
    p.age,
    p.position,
    p.hire_date
FROM
    players AS p
        JOIN
    skills_data AS sd ON p.skills_data_id = sd.id
WHERE
    age < 23 AND position = 'A'
        AND hire_date IS NULL
        AND sd.strength > 50
ORDER BY salary , age;

-- 7 ------------------------------------------------------
-- SET sql_mode = 'ONLY_FULL_GROUP_BY';

SELECT 
    t.`name` AS team_name,
    t.established,
    t.fan_base,
    COUNT(p.id) AS players_count
FROM
    teams AS t
        LEFT JOIN
    players AS p ON t.id = p.team_id
GROUP BY t.id
ORDER BY players_count DESC , fan_base DESC;

-- 8 ------------------------------------------------------
-- SET sql_mode = 'ONLY_FULL_GROUP_BY'; Judge don't work

SELECT 
    MAX(sd.speed) AS max_speed,
    t.name AS town_name,
    s.name AS stadium_name,
    te.name AS team_name,
    p.first_name
FROM
    towns AS t
        LEFT JOIN
    stadiums AS s ON t.id = s.town_id
        LEFT JOIN
    teams AS te ON s.id = te.stadium_id
        LEFT JOIN
    players AS p ON te.id = p.team_id
        LEFT JOIN
    skills_data AS sd ON sd.id = p.skills_data_id
WHERE
    te.name != 'Devify'
GROUP BY t.id
ORDER BY max_speed DESC , t.name;

-- max_speed | town_name | stadium_name | team_name | first_name |
-- ---------------------------------------------------------------
-- 97        | Smolensk  | Dabjam       | Pixonyx   | Perren     |
-- 92        | Bromma    | Zoovo        | Skyble    | Glory      |
-- 92        | Luhua     | Kare         | Tanoodle  | NULL       |
-- NULL      | Zavolzh'ye| Jaxspan      | Eire      | NULL       |

SELECT 
    MAX(sd.speed) AS max_speed, t.name AS town_name
FROM
    towns AS t
        LEFT JOIN
    stadiums AS s ON t.id = s.town_id
        LEFT JOIN
    teams AS te ON s.id = te.stadium_id
        LEFT JOIN
    players AS p ON te.id = p.team_id
        LEFT JOIN
    skills_data AS sd ON sd.id = p.skills_data_id
WHERE
    te.name != 'Devify'
GROUP BY t.id
ORDER BY max_speed DESC , t.name;

-- max_speed | town_name |
-- -----------------------
-- 97        | Smolensk  |
-- 92        | Bromma    |
-- 92        | Luhua     |
-- NULL      | Zavolzh'ye|

SELECT 
    c.name,
    COUNT(p.id) AS total_count_of_players,
    SUM(p.salary) AS total_sum_of_salaries
FROM
    countries AS c
        LEFT JOIN
    towns AS t ON c.id = t.country_id
        LEFT JOIN
    stadiums AS s ON t.id = s.town_id
        LEFT JOIN
    teams AS te ON s.id = te.stadium_id
        LEFT JOIN
    players AS p ON te.id = p.team_id
GROUP BY c.id
ORDER BY total_count_of_players DESC , c.name;

-- name	         | total_count_of_players |	total_sum_of_salaries
-- --------------------------------------------------------------
-- Sweden        | 28                     | 14968947.79
-- Brazil        | 18                     | 8352732.65
-- China         | 13                     | 7042890.51
-- Russia        | 7                      | 2230759.71
-- Thailand      | 0                      | NULL
-- United States | 0                      | NULL

-- 10 Judge works ------------------------------------------------------

DROP FUNCTION IF EXISTS udf_stadium_players_count;

DELIMITER //
CREATE FUNCTION udf_stadium_players_count(stadium_name VARCHAR(30))
RETURNS INT 
DETERMINISTIC
BEGIN
	DECLARE stadium_players_count INT;
    SET stadium_players_count := (SELECT COUNT(p.id) 
		FROM stadiums AS s
		LEFT JOIN teams AS t
		ON s.id = t.stadium_id
		LEFT JOIN players AS p
		ON t.id = p.team_id
        WHERE s.name = stadium_name);
    RETURN stadium_players_count;
END 
//
DELIMITER ;
-- ----------------------------------------------------- Judge don't work
DROP FUNCTION IF EXISTS udf_stadium_players_count;

DELIMITER //
CREATE FUNCTION udf_stadium_players_count(stadium_name VARCHAR(30))
RETURNS INT 
DETERMINISTIC
BEGIN
    RETURN (SELECT COUNT(p.id) 
		FROM stadiums AS s
		LEFT JOIN teams AS t
		ON s.id = t.stadium_id
		LEFT JOIN players AS p
		ON t.id = p.team_id
        WHERE s.name = stadium_name);
END 
//
DELIMITER ;

SELECT UDF_STADIUM_PLAYERS_COUNT('Jaxworks') AS `count`;
SELECT UDF_STADIUM_PLAYERS_COUNT('Linklinks') AS `count`; 
-- -----------------------------------------------
DELIMITER //
CREATE FUNCTION udf_stadium_players_count(stadium_name VARCHAR(30))
RETURNS INTEGER
DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(*)
	FROM players AS p
	JOIN teams AS t ON p.team_id = t.id
	LEFT JOIN stadiums AS s ON t.stadium_id = s.id
	WHERE s.name = stadium_name);
END
//
DELIMITER ;

-- 11 ------------------------------------------------------
-- SET sql_mode = 'ONLY_FULL_GROUP_BY';
DROP PROCEDURE IF EXISTS udp_find_playmaker;

DELIMITER //
CREATE PROCEDURE udp_find_playmaker(IN min_dribble_points INT, team_name VARCHAR(45))
BEGIN
	SELECT CONCAT_WS(' ', p.first_name, p.last_name) AS full_name, p.age, p.salary, sd.dribbling, sd.speed, t.name
	FROM teams AS t
	JOIN players AS p
	ON t.id = p.team_id
	JOIN skills_data AS sd
	ON sd.id = p.skills_data_id
	WHERE sd.dribbling > min_dribble_points AND t.name = team_name
	ORDER BY sd.speed DESC
	LIMIT 1;
END 
//
DELIMITER ;

CALL udp_find_playmaker (20, 'Skyble');

-- full_name    | age | salary   | dribbling | speed | team_name |
-- ---------------------------------------------------------------
-- Royal Deakes | 19  | 49162.77 | 33        | 92    | Skyble    |