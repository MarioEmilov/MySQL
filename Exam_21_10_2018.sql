# 00 Table design
CREATE DATABASE colonial_journey_management_system_db;
USE colonial_journey_management_system_db;

CREATE TABLE planets (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE spaceports (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    planet_id INT(11),
    CONSTRAINT fk_spaceports_planets FOREIGN KEY (planet_id)
        REFERENCES planets (id)
);

CREATE TABLE spaceships (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(30) NOT NULL,
    light_speed_rate INT(11) DEFAULT 0
);

CREATE TABLE journeys (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    journey_start DATETIME NOT NULL,
    journey_end DATETIME NOT NULL,
    purpose ENUM('Medical', 'Technical', 'Educational', 'Military') NOT NULL,
    destination_spaceport_id INT(11),
    spaceship_id INT(11),
    CONSTRAINT fk_journeys_spaceports FOREIGN KEY (destination_spaceport_id)
        REFERENCES spaceports (id),
    CONSTRAINT fk_journeys_spaceships FOREIGN KEY (spaceship_id)
        REFERENCES spaceships (id)
);

CREATE TABLE colonists (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    ucn CHAR(10) NOT NULL UNIQUE,
    birth_date DATE NOT NULL
);

CREATE TABLE travel_cards (
    id INT(11) PRIMARY KEY AUTO_INCREMENT,
    card_number CHAR(10) NOT NULL UNIQUE,
    job_during_journey ENUM('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook') NOT NULL,
    colonist_id INT(11),
    journey_id INT(11),
    CONSTRAINT fk_travel_cards_colonists FOREIGN KEY (colonist_id)
        REFERENCES colonists (id),
    CONSTRAINT fk_travel_cards_journeys FOREIGN KEY (journey_id)
        REFERENCES journeys (id)
);

# 1.Data insertion
INSERT INTO travel_cards(card_number, job_during_journey, colonist_id, journey_id)
    SELECT
      (
        CASE
          WHEN c.birth_date > '1980-01-01' THEN concat_ws('', year(c.birth_date), day(c.birth_date), substr(c.ucn, 1, 4))
          ELSE concat_ws('', year(c.birth_date), month(c.birth_date), substr(c.ucn, 7, 10))
        END
      ) AS card_number,
      (
        CASE
          WHEN c.id % 2 = 0 THEN 'Pilot'
          WHEN c.id % 3 = 0 THEN 'Cook'
          ELSE 'Engineer'
        END
      ) AS job_during_journey,
      c.id,
      (
        substr(c.ucn, 1,1)
      ) AS journey_id
    FROM colonists c
    WHERE c.id between 96 AND 100;

UPDATE journeys 
SET 
    purpose = (CASE
        WHEN id % 2 = 0 THEN 'Medical'
        WHEN id % 3 = 0 THEN 'Technical'
        WHEN id % 5 = 0 THEN 'Educational'
        WHEN id % 7 = 0 THEN 'Military'
        ELSE purpose
    END);

DELETE FROM colonists 
WHERE
    id NOT IN (SELECT 
        tc.colonist_id
    FROM
        travel_cards tc);

SELECT 
    tc.card_number, tc.job_during_journey
FROM
    travel_cards tc
ORDER BY tc.card_number;

SELECT 
    c.id,
    CONCAT_WS(' ', c.first_name, c.last_name) full_name,
    c.ucn
FROM
    colonists c
ORDER BY c.first_name , c.last_name , c.id;

SELECT 
    j.id, j.journey_start, j.journey_end
FROM
    journeys j
WHERE
    j.purpose = 'Military'
ORDER BY j.journey_start;

SELECT 
    c.id, CONCAT_WS(' ', c.first_name, c.last_name) full_name
FROM
    colonists c
        JOIN
    travel_cards tc ON c.id = tc.colonist_id
WHERE
    tc.job_during_journey = 'Pilot'
ORDER BY id;

SELECT 
    COUNT(c.id) count
FROM
    colonists c
        JOIN
    travel_cards tc ON c.id = tc.colonist_id
        JOIN
    journeys j ON tc.journey_id = j.id
WHERE
    j.purpose = 'Technical';

SELECT 
    ship.name spaceship_name, port.name spaceport_name
FROM
    spaceships ship
        JOIN
    journeys j ON ship.id = j.spaceship_id
        JOIN
    spaceports port ON j.destination_spaceport_id = port.id
ORDER BY ship.light_speed_rate DESC
LIMIT 1;

SELECT 
    s.name, s.manufacturer
FROM
    colonists c
        JOIN
    travel_cards tc ON tc.colonist_id = c.id
        JOIN
    journeys j ON tc.journey_id = j.id
        JOIN
    spaceships s ON j.spaceship_id = s.id
WHERE
    YEAR(c.birth_date) > YEAR(DATE_SUB('2019-01-01', INTERVAL 30 YEAR))
        AND tc.job_during_journey = 'Pilot'
ORDER BY s.name;

SELECT 
    p.name planet_name, sp.name spaceport_name
FROM
    planets p
        JOIN
    spaceports sp ON p.id = sp.planet_id
        JOIN
    journeys j ON sp.id = j.destination_spaceport_id
WHERE
    j.purpose = 'Educational'
ORDER BY spaceport_name DESC;

SELECT 
    pl.planet_name, COUNT(pl.planet_name) journeys_count
FROM
    (SELECT 
        p.name planet_name
    FROM
        planets p
    JOIN spaceports sp ON p.id = sp.planet_id
    JOIN journeys j ON sp.id = j.destination_spaceport_id) pl
GROUP BY planet_name
ORDER BY journeys_count DESC , planet_name;

SELECT 
    j.id,
    p.name planet_name,
    sp.name spaceport_name,
    j.purpose journey_purpose
FROM
    journeys j
        JOIN
    spaceports sp ON j.destination_spaceport_id = sp.id
        JOIN
    planets p ON sp.planet_id = p.id
ORDER BY DATEDIFF(j.journey_end, j.journey_start)
LIMIT 1;

SELECT 
    tc.job_during_journey
FROM
    travel_cards tc
WHERE
    tc.journey_id = (SELECT 
            j.id
        FROM
            journeys j
        ORDER BY DATEDIFF(j.journey_end, j.journey_start) DESC
        LIMIT 1)
GROUP BY tc.job_during_journey
ORDER BY COUNT(tc.job_during_journey)
LIMIT 1;

# 15.Get colonists count
DELIMITER //
CREATE FUNCTION udf_count_colonists_by_destination_planet(planet_name VARCHAR(30))
  RETURNS INT
  BEGIN
    DECLARE c_count INT;
    SET c_count := (
      SELECT count(c.id)
      FROM colonists c
      JOIN travel_cards tc on c.id = tc.colonist_id
      JOIN journeys j on tc.journey_id = j.id
      JOIN spaceports s on j.destination_spaceport_id = s.id
      JOIN planets p on s.planet_id = p.id
      WHERE p.name = planet_name
    );
    RETURN c_count;
  END 
//
DELIMITER ;


# 16.Modify spaceship
DELIMITER //
CREATE PROCEDURE udp_modify_spaceship_light_speed_rate(spaceship_name VARCHAR(50), light_speed_rate_increse INT(11))
  BEGIN
    if (SELECT count(ss.name) FROM spaceships ss WHERE ss.name = spaceship_name > 0) THEN
      UPDATE spaceships ss
        SET ss.light_speed_rate = ss.light_speed_rate + light_speed_rate_increse
        WHERE name = spaceship_name;
    ELSE
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Spaceship you are trying to modify does not exists.';
      ROLLBACK;
    END IF;
  END 
//
DELIMITER ;