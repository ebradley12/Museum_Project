
-- Drop and create new database 
DROP DATABASE IF EXISTS museum;
CREATE DATABASE museum;
\c museum;

-- Drop tables
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS floor CASCADE;
DROP TABLE IF EXISTS exhibition CASCADE;
DROP TABLE IF EXISTS request CASCADE;
DROP TABLE IF EXISTS rating CASCADE;
DROP TABLE IF EXISTS request_interaction CASCADE;
DROP TABLE IF EXISTS rating_interaction CASCADE;

-- Create department table
CREATE TABLE department (
    department_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

-- Create floor table
CREATE TABLE floor (
    floor_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    floor_name VARCHAR(100) NOT NULL
);

-- Create exhibition table
CREATE TABLE exhibition (
    exhibition_id SMALLINT PRIMARY KEY,
    exhibition_name VARCHAR(100) NOT NULL,
    exhibition_description TEXT,
    department_id SMALLINT NOT NULL,
    floor_id SMALLINT NOT NULL,
    exhibition_start_date DATE 
    CHECK (exhibition_start_date >= '1900-01-01' AND exhibition_start_date <= CURRENT_DATE),
    public_id TEXT UNIQUE,
    FOREIGN KEY (department_id) REFERENCES department(department_id),
    FOREIGN KEY (floor_id) REFERENCES floor(floor_id)
);

-- Create request table
CREATE TABLE request (
    request_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_value SMALLINT 
    CHECK (request_value IN (0, 1)),
    request_description VARCHAR(100) NOT NULL
);

-- Create rating table
CREATE TABLE rating (
    rating_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rating_value SMALLINT CHECK (rating_value BETWEEN 0 AND 4),
    rating_description VARCHAR(100) NOT NULL
);

-- Create request interaction table
CREATE TABLE request_interaction (
    request_interaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    exhibition_id SMALLINT NOT NULL,
    request_id SMALLINT NOT NULL,
    event_at TIMESTAMPTZ NOT NULL CHECK (event_at <= NOW()),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id),
    FOREIGN KEY (request_id) REFERENCES request(request_id)
);

-- Create rating interaction table
CREATE TABLE rating_interaction (
    rating_interaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    exhibition_id SMALLINT NOT NULL,
    rating_id SMALLINT NOT NULL,
    event_at TIMESTAMPTZ NOT NULL CHECK (event_at <= NOW()),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id),
    FOREIGN KEY (rating_id) REFERENCES rating(rating_id)
);

-- Indexes
CREATE INDEX exhibition_department_idx ON exhibition (department_id);
CREATE INDEX exhibition_floor_idx ON exhibition (floor_id);
CREATE INDEX exhibition_start_date_idx ON exhibition (exhibition_start_date);
CREATE INDEX request_value_idx ON request (request_value);
CREATE INDEX rating_value_idx ON rating (rating_value);

-- Insert departments
INSERT INTO department (department_name) VALUES
('Entomology'),
('Geology'),
('Paleontology'),
('Zoology'),
('Ecology');

-- Insert floors
INSERT INTO floor (floor_name) VALUES
('1'),
('2'),
('3'),
('Vault');

-- Insert exhibitions
INSERT INTO exhibition (exhibition_id, exhibition_name, exhibition_description, department_id, floor_id, exhibition_start_date, public_id)
VALUES
(0, 'Measureless to Man', 'An immersive 3D experience: delve deep into a previously-inaccessible cave system.', 2, 1, '2021-08-23', 'EXH_00'),
(1, 'Adaptation', 'How insect evolution has kept pace with an industrialised world', 1, 4, '2019-07-01', 'EXH_01'),
(2, 'The Crenshaw Collection', 'An exhibition of 18th Century watercolours, mostly focused on South American wildlife.', 4, 2, '2021-03-03', 'EXH_02'),
(3, 'Cetacean Sensations', 'Whales: from ancient myth to critically endangered.', 4, 1, '2019-07-01', 'EXH_03'),
(4, 'Our Polluted World', 'A hard-hitting exploration of humanity"s impact on the environment.', 5, 3, '2021-05-12', 'EXH_04'),
(5, 'Thunder Lizards', 'How new research is making scientists rethink what dinosaurs really looked like.', 3, 1, '2023-02-01', 'EXH_05');

-- Insert requests (assistance and emergency types)
INSERT INTO request (request_value, request_description) VALUES
(0, 'Assistance'),
(1, 'Emergency');

-- Insert ratings (0-4 scale)
INSERT INTO rating (rating_value, rating_description) VALUES
(0, 'Terrible'),
(1, 'Bad'),
(2, 'Neutral'),
(3, 'Good'),
(4, 'Amazing');

-- psql postgres -f schema.sql


