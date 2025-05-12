DROP SCHEMA IF EXISTS pulse_university;
CREATE SCHEMA pulse_university;
USE pulse_university;

CREATE TABLE continent (                       
  continent_name VARCHAR(50) NOT NULL,
  PRIMARY KEY  (continent_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE country (
	country_name VARCHAR(50) NOT NULL,
	continent_name VARCHAR(50) NOT NULL,
	PRIMARY KEY (country_name),
	FOREIGN KEY (continent_name) REFERENCES continent(continent_name)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE 
) ENGINE = InnoDB DEFAULT CHARSET = utf8;

CREATE TABLE city (
  city_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  city_name VARCHAR(50) NOT NULL,
  country_name VARCHAR(50) NOT NULL,
  PRIMARY KEY  (city_id),
  FOREIGN KEY (country_name) REFERENCES country (country_name) 
	ON DELETE RESTRICT 
	ON UPDATE CASCADE,
  UNIQUE (city_name,country_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE address (
	address_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	street_name VARCHAR (80) NOT NULL,
	street_number INT UNSIGNED NOT NULL,
	city_id INT UNSIGNED NOT NULL,
	PRIMARY KEY (address_id),
	FOREIGN KEY (city_id) REFERENCES city (city_id)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE, 
	UNIQUE (street_name,street_number,city_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE location (
	location_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	address_id INT UNSIGNED NOT NULL,
	latitude FLOAT (7,4) NOT NULL,
	longitude FLOAT (7,4) NOT NULL, 
	location_description TEXT DEFAULT NULL,
	location_image VARCHAR(255) DEFAULT NULL, 
	UNIQUE (latitude, longitude),
	PRIMARY KEY (location_id),
	FOREIGN KEY (address_id) REFERENCES address (address_id) 
		ON DELETE RESTRICT
		ON UPDATE CASCADE 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE festival (
  festival_year YEAR NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  poster VARCHAR(255) DEFAULT NULL, 
  festival_description TEXT DEFAULT NULL,
  location_id INT UNSIGNED, 
  PRIMARY KEY (festival_year),
  FOREIGN KEY (location_id) REFERENCES location(location_id)
	ON DELETE RESTRICT  
	ON UPDATE CASCADE,
  CONSTRAINT chk_year_match CHECK (
    YEAR(start_date) = festival_year AND YEAR(end_date) = festival_year
  ),
  CONSTRAINT chk_date_order CHECK (
    start_date <= end_date
  ),
  CONSTRAINT uk_festival_location UNIQUE (festival_year,location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE stage (
	location_id INT UNSIGNED NOT NULL,
	stage_name VARCHAR (80) NOT NULL ,
	stage_description TEXT DEFAULT NULL,
	capacity INT UNSIGNED NOT NULL ,
	PRIMARY KEY (location_id, stage_name),
	FOREIGN KEY (location_id) REFERENCES location(location_id)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE stage_equipment (
    location_id INT UNSIGNED NOT NULL,
	stage_name  VARCHAR (80) NOT NULL,
    equipment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    equipment_type  VARCHAR(100) NOT NULL,
    quantity INT UNSIGNED ,
	equipment_image VARCHAR(255) DEFAULT NULL, 
    PRIMARY KEY (equipment_id),
    FOREIGN KEY (location_id, stage_name) REFERENCES stage(location_id, stage_name) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	UNIQUE (location_id,equipment_type,stage_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE event (
	event_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	event_name VARCHAR (100),
	festival_year YEAR NOT NULL,
	location_id INT UNSIGNED NOT NULL,
	stage_name VARCHAR (80) NOT NULL ,
	event_date DATE NOT NULL,
	start_time TIME NOT NULL,
	end_time TIME NOT NULL, 
	PRIMARY KEY (event_id),
	FOREIGN KEY (festival_year) REFERENCES festival(festival_year)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (location_id, stage_name) REFERENCES stage(location_id, stage_name)
		ON DELETE RESTRICT
		ON UPDATE CASCADE,
	UNIQUE(event_name,festival_year,event_date),
	CONSTRAINT chk_time_order CHECK (
		start_time < end_time
	),
	CONSTRAINT chk_duration_event CHECK (TIMEDIFF(end_time,start_time) BETWEEN '00:00:00' AND '24:00:00')
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
	DELIMITER $$
	CREATE TRIGGER event_in_festival_ins BEFORE INSERT ON event FOR EACH ROW BEGIN
	IF (NEW.event_date NOT BETWEEN ( SELECT start_date FROM festival WHERE festival_year = NEW.festival_year ) AND (SELECT end_date FROM festival WHERE festival_year = NEW.festival_year))
	THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Event date is not within the festival dates';  
	END IF; 
	END $$
	
	CREATE TRIGGER event_in_festival_upd BEFORE UPDATE ON event FOR EACH ROW BEGIN
	IF (NEW.event_date NOT BETWEEN ( SELECT start_date FROM festival WHERE festival_year = NEW.festival_year ) AND (SELECT end_date FROM festival WHERE festival_year = NEW.festival_year))
	THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Event date is not within the festival dates';  
	END IF; 
	END $$
	
	CREATE TRIGGER no_overlap_event_ins BEFORE INSERT ON event FOR EACH ROW BEGIN 
	IF EXISTS (SELECT 1 FROM event WHERE festival_year = new.festival_year AND event_date = new.event_date AND location_id = new.location_id AND stage_name = new.stage_name
		AND ((new.start_time < end_time) AND (new.end_time > start_time)))
    THEN  SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'overlapping events';
	END IF;
	END$$ 
	CREATE TRIGGER no_overlap_event_upd BEFORE UPDATE ON event FOR EACH ROW BEGIN 
	IF EXISTS (SELECT 1 FROM event WHERE festival_year = new.festival_year AND event_date = new.event_date AND location_id = new.location_id AND stage_name = new.stage_name
		AND ((new.start_time < end_time) AND (new.end_time > start_time) AND event_id != new.event_id))
    THEN  SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'overlapping events';
	END IF;
	END$$ 
	DELIMITER ; 

CREATE TABLE staff_role (
	staff_role VARCHAR(30) PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO staff_role (staff_role) VALUES
('technical'),
('security'),
('support');

CREATE TABLE staff (
	staff_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR (20) NOT NULL,
	surname VARCHAR(30) NOT NULL ,
	age INT UNSIGNED NOT NULL,
    staff_role VARCHAR (50) NOT NULL, 
    email VARCHAR (50) NOT NULL,
	picture VARCHAR(255) DEFAULT NULL,
	staff_description TEXT DEFAULT NULL, 
	experience_level VARCHAR (20) NOT NULL,
	PRIMARY KEY (staff_id),
	FOREIGN KEY (staff_role) REFERENCES staff_role(staff_role)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
	UNIQUE(email),
	CONSTRAINT chk_age CHECK (age BETWEEN 18 AND 78)	
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE staff_assignment (
    staff_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    stage_name VARCHAR(80) NOT NULL,
    festival_year YEAR NOT NULL,
    PRIMARY KEY (staff_id, festival_year),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (location_id, stage_name) REFERENCES stage(location_id, stage_name)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (festival_year, location_id) REFERENCES festival(festival_year, location_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;





DELIMITER $$
CREATE TRIGGER staff_level_trigger_ins
BEFORE INSERT ON staff
FOR EACH ROW
BEGIN
    
    IF NEW.age BETWEEN 18 AND 25 THEN
SET NEW.experience_level = 'beginner';
ELSEIF NEW.age BETWEEN 26 AND 35 THEN
    SET NEW.experience_level = 'intermediate';
ELSEIF NEW.age BETWEEN 35 AND 50 THEN 
    SET NEW.experience_level = 'experienced';
ELSE 
SET NEW.experience_level = 'very experienced';
    END IF;
END $$ 

CREATE TRIGGER staff_level_trigger_upd
BEFORE UPDATE ON staff
FOR EACH ROW
BEGIN
    
    IF NEW.age BETWEEN 18 AND 25 THEN
SET NEW.experience_level = 'beginner';
ELSEIF NEW.age BETWEEN 26 AND 35 THEN
    SET NEW.experience_level = 'intermediate';
ELSEIF NEW.age BETWEEN 35 AND 50 THEN 
    SET NEW.experience_level = 'experienced';
ELSE 
SET NEW.experience_level = 'very experienced';
    END IF;
END $$ 

DELIMITER ;

CREATE TABLE staff_phone (
	staff_id INT UNSIGNED NOT NULL,
	phone_number DECIMAL(13,0) NOT NULL,
	PRIMARY KEY (staff_id, phone_number),
	FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE performance_type (
	performance_type VARCHAR(30) PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO performance_type (performance_type) VALUES
('headline'),
('warm up'),
('special guest');

CREATE TABLE artist_status (
	artist_status VARCHAR(4) NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO artist_status (artist_status) VALUES
('solo'),
('band');

CREATE TABLE artist (
	artist_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(20) NOT NULL,
	surname VARCHAR(30) NOT NULL,
	nickname VARCHAR(30),
	dob DATE NOT NULL, 
	picture VARCHAR(255) DEFAULT NULL,
	webpage VARCHAR(255),
	instagram VARCHAR(50),
	PRIMARY KEY (artist_id),
	UNIQUE (first_name,surname,nickname),
	UNIQUE (instagram),
	UNIQUE (webpage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE genre (
	genre_name VARCHAR(30) NOT NULL,
	PRIMARY KEY(genre_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE subgenre(
	genre_name VARCHAR(30) NOT NULL,
	subgenre_name VARCHAR(30) NOT NULL,
	PRIMARY KEY (genre_name,subgenre_name),
	FOREIGN KEY (genre_name) REFERENCES genre(genre_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE artistgenre (
	artist_id INT UNSIGNED NOT NULL, 
	genre_name VARCHAR(30) NOT NULL,
	subgenre_name VARCHAR(30) NOT NULL,
	PRIMARY KEY(artist_id,genre_name,subgenre_name),
	FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT,
	FOREIGN KEY (genre_name,subgenre_name) REFERENCES subgenre(genre_name,subgenre_name)
		ON UPDATE CASCADE
		ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE band (
	band_name VARCHAR(60) NOT NULL,
	genre_name VARCHAR(30) NOT NULL,
	subgenre_name VARCHAR(30) NOT NULL,
	formation_dt DATE NOT NULL,
	picture VARCHAR(255) DEFAULT NULL,
	webpage VARCHAR(255),
	instagram VARCHAR(50),
	PRIMARY KEY (band_name),
	FOREIGN KEY (genre_name,subgenre_name) REFERENCES subgenre (genre_name,subgenre_name)
		ON UPDATE CASCADE
		ON DELETE RESTRICT,
	UNIQUE (instagram),
	UNIQUE (webpage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE band_members (
	band_name VARCHAR(60) NOT NULL,
	artist_id INT UNSIGNED NOT NULL,
	PRIMARY KEY (band_name,artist_id),
	FOREIGN KEY (band_name) REFERENCES band (band_name)
		ON UPDATE CASCADE 
		ON DELETE RESTRICT,
	FOREIGN KEY (artist_id) REFERENCES artist (artist_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
CREATE TABLE performance (
	performance_id INT UNSIGNED AUTO_INCREMENT,
	performance_type VARCHAR(30) NOT NULL,
	artist_status VARCHAR(4) NOT NULL,
	start_time TIME NOT NULL,
	end_time TIME NOT NULL,
	event_id INT UNSIGNED NOT NULL,
	artist_id INT UNSIGNED ,	
	band_name VARCHAR(60),
	break_time TIME NOT NULL, 
	PRIMARY KEY (performance_id),
	FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (event_id) REFERENCES event(event_id)
		ON DELETE RESTRICT
		ON UPDATE CASCADE,
	FOREIGN KEY (band_name) REFERENCES band (band_name)
		ON DELETE RESTRICT
		ON UPDATE CASCADE,
	FOREIGN KEY (performance_type) REFERENCES performance_type(performance_type)
		ON DELETE RESTRICT
		ON UPDATE CASCADE,
	FOREIGN KEY (artist_status) REFERENCES artist_status(artist_status)
		ON DELETE RESTRICT
		ON UPDATE CASCADE,	
	CONSTRAINT chk_time CHECK (
		(TIMEDIFF(end_time,start_time) BETWEEN '00:00:00' AND '03:00:00')
	),
	CONSTRAINT chk_break CHECK (break_time BETWEEN '00:05:00' AND '00:30:00'),
	CONSTRAINT chk_solo_or_band CHECK ((artist_status = 'solo' AND artist_id IS NOT NULL AND band_name IS NULL) OR (artist_status = 'band' AND artist_id IS NULL AND band_name IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DELIMITER $$
	CREATE TRIGGER performance_in_event_ins BEFORE INSERT ON performance FOR EACH ROW BEGIN
	IF ((NEW.start_time NOT BETWEEN ( SELECT start_time FROM event WHERE event_id = NEW.event_id ) AND (SELECT end_time FROM event WHERE event_id = NEW.event_id))
		OR (ADDTIME(NEW.end_time,NEW.break_time) NOT BETWEEN ( SELECT start_time FROM event WHERE event_id = NEW.event_id ) AND (SELECT end_time FROM event WHERE event_id = NEW.event_id)))
	THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'performance is not within event time';  
	END IF; 
	END $$
	
	CREATE TRIGGER performance_in_event_upd BEFORE UPDATE ON performance FOR EACH ROW BEGIN
	IF ((NEW.start_time NOT BETWEEN ( SELECT start_time FROM event WHERE event_id = NEW.event_id ) AND (SELECT end_time FROM event WHERE event_id = NEW.event_id))
		OR (ADDTIME(NEW.end_time,NEW.break_time) NOT BETWEEN ( SELECT start_time FROM event WHERE event_id = NEW.event_id ) AND (SELECT end_time FROM event WHERE event_id = NEW.event_id)))
	THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'performance is not within event time';  
	END IF; 
	END $$
	
	CREATE TRIGGER no_overlap_performance_ins BEFORE INSERT ON performance FOR EACH ROW BEGIN 
	IF EXISTS (SELECT 1 FROM performance WHERE event_id = new.event_id  
	 AND ((new.start_time < ADDTIME(end_time,break_time)) AND (ADDTIME(new.end_time,new.break_time) > start_time)))
    THEN  SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'overlapping performances';
	END IF;
	END$$ 
	
	CREATE TRIGGER no_overlap_performance_upd BEFORE UPDATE ON performance FOR EACH ROW BEGIN 
	IF EXISTS (SELECT 1 FROM performance WHERE event_id = new.event_id  
	 AND ((new.start_time < ADDTIME(end_time,break_time)) AND (ADDTIME(new.end_time,new.break_time) > start_time) AND performance_id != new.performance_id))
    THEN  SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'overlapping performances';
	END IF;
	END$$
	
DELIMITER ; 



DELIMITER $$

CREATE TRIGGER prevent_artist_band_double_booking_insert
BEFORE INSERT ON performance
FOR EACH ROW
BEGIN
    DECLARE new_event_date DATE;
    
    SELECT event_date INTO new_event_date 
    FROM event 
    WHERE event_id = NEW.event_id;
    
    IF NEW.artist_status = 'solo' THEN
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            WHERE p.artist_id = NEW.artist_id
                AND p.artist_status = 'solo'
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Artist is already booked at this time on another stage';
        END IF;
        
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            JOIN band_members bm ON bm.band_name = p.band_name
            WHERE p.artist_status = 'band'
                AND bm.artist_id = NEW.artist_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Artist is already booked with their band at this time';
        END IF;
    
    ELSEIF NEW.artist_status = 'band' THEN
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            WHERE p.band_name = NEW.band_name
                AND p.artist_status = 'band'
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Band is already booked at this time on another stage';
        END IF;
        
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            JOIN band_members bm ON bm.band_name = NEW.band_name
            WHERE p.artist_status = 'solo'
                AND p.artist_id = bm.artist_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A band member is already booked as solo artist at this time';
        END IF;
    END IF;
END$$

CREATE TRIGGER prevent_artist_band_double_booking_update
BEFORE UPDATE ON performance
FOR EACH ROW
BEGIN
    DECLARE new_event_date DATE;
    
    SELECT event_date INTO new_event_date 
    FROM event 
    WHERE event_id = NEW.event_id;
    
    IF NEW.artist_status = 'solo' THEN
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            WHERE p.artist_id = NEW.artist_id
                AND p.artist_status = 'solo'
                AND p.performance_id != NEW.performance_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Artist is already booked at this time on another stage';
        END IF;
        
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            JOIN band_members bm ON bm.band_name = p.band_name
            WHERE p.artist_status = 'band'
                AND bm.artist_id = NEW.artist_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Artist is already booked with their band at this time';
        END IF;
    
    ELSEIF NEW.artist_status = 'band' THEN
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            WHERE p.band_name = NEW.band_name
                AND p.artist_status = 'band'
                AND p.performance_id != NEW.performance_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Band is already booked at this time on another stage';
        END IF;
        
        IF EXISTS (
            SELECT 1 FROM performance p
            JOIN event e ON p.event_id = e.event_id
            JOIN band_members bm ON bm.band_name = NEW.band_name
            WHERE p.artist_status = 'solo'
                AND p.artist_id = bm.artist_id
                AND e.event_date = new_event_date
                AND (
                    (NEW.start_time < ADDTIME(p.end_time, p.break_time) AND 
                     ADDTIME(NEW.end_time, NEW.break_time) > p.start_time)
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A band member is already booked as solo artist at this time';
        END IF;
    END IF;
END$$

DELIMITER ;


CREATE TABLE visitor (
	visitor_id INT UNSIGNED AUTO_INCREMENT,
	first_name VARCHAR(20) NOT NULL,
	surname VARCHAR(30) NOT NULL,
	age INT UNSIGNED NOT NULL,
	email VARCHAR (50) NOT NULL,
	phone_number DECIMAL(13,0),
	PRIMARY KEY (visitor_id),
	UNIQUE (email),
	CONSTRAINT chk_visitor_age CHECK ( age BETWEEN 12 AND 99 )
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE purchase_type (
    purchase_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (purchase_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO purchase_type (purchase_type) VALUES
('credit_card'),
('debit_card'),
('e-banking');

CREATE TABLE ticket_price (
    ticket_type VARCHAR(20),
    price DECIMAL(10,2) NOT NULL,
	PRIMARY KEY (ticket_type,price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO ticket_price (ticket_type, price) VALUES
('VIP', 100.00),
('general', 60.00),
('backstage', 250.00);


CREATE TABLE ticket (
	ticket_id INT UNSIGNED AUTO_INCREMENT,
	visitor_id INT UNSIGNED NOT NULL, 
	event_id INT UNSIGNED NOT NULL,
	ean_code CHAR(13) NOT NULL,
	ticket_type VARCHAR(20) NOT NULL,
	purchase_type VARCHAR(20) NOT NULL,
	purchase_date DATE NOT NULL,
	price DECIMAL(10,2) NOT NULL,
    validated BOOLEAN DEFAULT FALSE,
	UNIQUE(ean_code),
	UNIQUE (visitor_id,event_id),
    CONSTRAINT chk_ean_syntax CHECK (ean_code REGEXP '^[0-9]{13}$'),
	PRIMARY KEY (ticket_id),
	FOREIGN KEY (event_id) REFERENCES event (event_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT,
	FOREIGN KEY (visitor_id) REFERENCES visitor (visitor_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT,
    FOREIGN KEY (ticket_type,price) REFERENCES ticket_price (ticket_type,price)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (purchase_type) REFERENCES purchase_type (purchase_type)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
DELIMITER $$
CREATE TRIGGER chk_purchase_date BEFORE INSERT ON ticket FOR EACH ROW BEGIN
DECLARE d DATE ;
SELECT e.event_date INTO d FROM event e WHERE e.event_id = new.event_id ;
IF (new.purchase_date > d) THEN 
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'ticket cannot be purchased after event';
END IF;
END $$

DELIMITER ;



CREATE TABLE resell_queue (
    queue_id INT UNSIGNED AUTO_INCREMENT,
    visitor_id INT UNSIGNED NOT NULL,
    ticket_id INT UNSIGNED,
    ticket_type VARCHAR(20),
    visitor_status VARCHAR(10) NOT NULL,
    event_id INT UNSIGNED,
    interest_date DATE,
    sell_date DATE,
    CONSTRAINT valid_status CHECK (visitor_status IN ('buyer', 'seller')),
    CONSTRAINT seller_requirements CHECK (
        visitor_status != 'seller' OR 
        (ticket_id IS NOT NULL AND sell_date IS NOT NULL)
    ),
    CONSTRAINT buyer_requirements CHECK (
        visitor_status != 'buyer' OR 
        (interest_date IS NOT NULL AND event_id IS NOT NULL AND ticket_type IS NOT NULL)
    ),
	PRIMARY KEY (queue_id),
    FOREIGN KEY (visitor_id) REFERENCES visitor (visitor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (ticket_id) REFERENCES ticket (ticket_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (event_id) REFERENCES event (event_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (ticket_type) REFERENCES ticket_price (ticket_type)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DELIMITER $$ 
CREATE TRIGGER capacity_check_resell 
BEFORE INSERT ON ticket 
FOR EACH ROW 
BEGIN 
	DECLARE stg_c INT UNSIGNED;
	DECLARE vip_count INT UNSIGNED;
	DECLARE total_count INT UNSIGNED; 
	SELECT s.capacity INTO stg_c 
	FROM event e 
	JOIN stage s ON e.location_id = s.location_id AND e.stage_name = s.stage_name
	WHERE e.event_id = NEW.event_id;
	
	SELECT COUNT(*) INTO total_count FROM ticket WHERE event_id = NEW.event_id;
	SELECT COUNT(*) INTO vip_count FROM ticket WHERE event_id = NEW.event_id AND ticket_type = 'VIP';
	IF (NEW.ticket_type = 'VIP' AND vip_count >= 0.1*stg_c) THEN 
		INSERT INTO resell_queue (event_id, ticket_type, interest_date, visitor_id, visitor_status)
		VALUES (NEW.event_id, NEW.ticket_type, NEW.purchase_date, NEW.visitor_id, 'buyer');
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'capacity exceeded, redirecting to resell queue';
	ELSEIF (total_count >= stg_c) THEN 
		INSERT INTO resell_queue (event_id, ticket_type, interest_date, visitor_id, visitor_status)
		VALUES (NEW.event_id, NEW.ticket_type, NEW.purchase_date, NEW.visitor_id, 'buyer');
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'capacity exceeded, redirecting to resell queue';
	END IF;
END $$
DELIMITER ;

CREATE TABLE rating (
    rating_id INT UNSIGNED AUTO_INCREMENT,
    visitor_id INT UNSIGNED NOT NULL,
    performance_id INT UNSIGNED NOT NULL,
    performance_score TINYINT NOT NULL,      
    sound_light_score TINYINT NOT NULL,       
    stage_presence_score TINYINT NOT NULL,    
    organization_score TINYINT NOT NULL,      
    overall_score TINYINT NOT NULL,          
    comment TEXT,
    rating_date DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (rating_id),
    FOREIGN KEY (visitor_id) REFERENCES visitor(visitor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (performance_id) REFERENCES performance(performance_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_likert CHECK (
        performance_score BETWEEN 1 AND 5 AND
        sound_light_score BETWEEN 1 AND 5 AND
        stage_presence_score BETWEEN 1 AND 5 AND
        organization_score BETWEEN 1 AND 5 AND
        overall_score BETWEEN 1 AND 5
    ),
    UNIQUE(visitor_id, performance_id)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DELIMITER $$

CREATE TRIGGER valid_rating 
BEFORE INSERT ON rating 
FOR EACH ROW 
BEGIN
    DECLARE event_id_for_performance INT UNSIGNED;
    DECLARE ticket_exists INT;
    DECLARE ticket_validated INT;
    
    SELECT event_id INTO event_id_for_performance
    FROM performance 
    WHERE performance_id = NEW.performance_id;
    
    SELECT COUNT(*) INTO ticket_exists
    FROM ticket
    WHERE visitor_id = NEW.visitor_id
      AND event_id = event_id_for_performance;
      
    SELECT COUNT(*) INTO ticket_validated
    FROM ticket
    WHERE visitor_id = NEW.visitor_id
      AND event_id = event_id_for_performance
      AND validated = TRUE;
    
    IF ticket_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor does not have a ticket for this event';
    ELSEIF ticket_validated = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor has a ticket but it is not validated';
    END IF;
END $$

DELIMITER ;

DELIMITER $$
CREATE TRIGGER chk_resell_date 
BEFORE INSERT ON resell_queue 
FOR EACH ROW 
BEGIN
	DECLARE d DATE;
	DECLARE v BOOLEAN;
	
	IF (NEW.visitor_status = 'seller') THEN 
        SELECT t.validated INTO v from ticket t where t.ticket_id = NEW.ticket_id;
		SELECT e.event_date INTO d FROM event e JOIN ticket t ON e.event_id = t.event_id  WHERE e.event_id = NEW.event_id; 
		IF (NEW.sell_date > d OR v = TRUE) THEN 
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'ticket cannot be sold after event/being validated';
		END IF;
	END IF;
END $$

DELIMITER $$
CREATE TRIGGER chk_interest_date 
BEFORE INSERT ON resell_queue 
FOR EACH ROW 
BEGIN
	DECLARE d DATE;
	IF (NEW.visitor_status = 'buyer') THEN 
		SELECT e.event_date INTO d FROM event e WHERE e.event_id = NEW.event_id; 
		IF (NEW.interest_date > d) THEN 
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'buyer cant express interest after event';
		END IF;
	END IF;
END $$

DELIMITER $$

CREATE TRIGGER prevent_artist_consecutive_years 
BEFORE INSERT ON performance 
FOR EACH ROW 
BEGIN
    DECLARE consecutive_years INT;

    SELECT COUNT(DISTINCT f.festival_year)
    INTO consecutive_years
    FROM performance p
    JOIN event e ON p.event_id = e.event_id
    JOIN festival f ON e.festival_year = f.festival_year
    LEFT JOIN band_members bm ON bm.band_name = p.band_name
    WHERE (p.artist_id = NEW.artist_id OR bm.artist_id = NEW.artist_id)
      AND f.festival_year >= (SELECT MAX(festival_year) - 2 FROM festival);

    IF consecutive_years >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Artist cannot perform at the festival more than 3 consecutive years';
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER match_buyer_seller
BEFORE INSERT ON resell_queue
FOR EACH ROW
BEGIN
    DECLARE matched_ticket_id INT;

    IF NEW.visitor_status = 'buyer' THEN
        SELECT rq.ticket_id INTO matched_ticket_id
        FROM resell_queue rq
        WHERE rq.visitor_status = 'seller'
          AND rq.ticket_type = NEW.ticket_type
          AND rq.event_id = NEW.event_id
        ORDER BY rq.sell_date ASC, rq.queue_id ASC
        LIMIT 1;

        IF matched_ticket_id IS NOT NULL THEN
            UPDATE ticket
            SET visitor_id = NEW.visitor_id,
                validated = TRUE
            WHERE ticket_id = matched_ticket_id;

            DELETE FROM resell_queue
            WHERE ticket_id = matched_ticket_id
              AND visitor_status = 'seller';

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Buyer matched with a seller. Ticket updated.';
        END IF;

    ELSEIF NEW.visitor_status = 'seller' THEN
        SELECT rq.ticket_id INTO matched_ticket_id
        FROM resell_queue rq
        WHERE rq.visitor_status = 'buyer'
          AND rq.ticket_type = NEW.ticket_type
          AND rq.event_id = NEW.event_id
        ORDER BY rq.interest_date ASC, rq.queue_id ASC
        LIMIT 1;

        IF matched_ticket_id IS NOT NULL THEN
            UPDATE ticket
            SET visitor_id = (
                SELECT visitor_id
                FROM resell_queue
                WHERE ticket_id = matched_ticket_id
                  AND visitor_status = 'buyer'
                LIMIT 1
            ),
                validated = TRUE
            WHERE ticket_id = matched_ticket_id;

            DELETE FROM resell_queue
            WHERE ticket_id = matched_ticket_id
              AND visitor_status = 'buyer';

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Seller matched with a buyer. Ticket updated.';
        END IF;
    END IF;
END $$

DELIMITER ;