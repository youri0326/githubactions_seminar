CREATE DATABASE IF NOT EXISTS sampledb DEFAULT CHARACTER SET utf8mb4;

USE sampledb;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
('Taro Yamada', 'taro@example.com'),
('Hanako Suzuki', 'hanako@example.com');
