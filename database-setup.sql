-- DevOps Database Setup Script
-- This script creates the database and tables for the Concert Backend project

-- Create database
CREATE DATABASE IF NOT EXISTS concert_db;
USE concert_db;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS favs;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(255),
    company VARCHAR(150),
    website VARCHAR(150),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_name (name)
);

-- Create events table
CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    location VARCHAR(255),
    start_date DATETIME NOT NULL,
    end_date DATETIME,
    banner_image VARCHAR(255),
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_start_date (start_date),
    INDEX idx_category (category),
    INDEX idx_user_id (user_id)
);

-- Create tickets table
CREATE TABLE tickets (
    tk_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    tk_types VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tk_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    INDEX idx_event_id (event_id),
    INDEX idx_price (price)
);

-- Create orders table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    tk_id INT NOT NULL,
    card_type VARCHAR(50),
    card_number VARCHAR(50),
    card_holder_name VARCHAR(100),
    card_exp VARCHAR(10),
    cvv2 VARCHAR(10),
    tax DECIMAL(10,2),
    total_price DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'PENDING',
    order_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quantity INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (tk_id) REFERENCES tickets(tk_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_event_id (event_id),
    INDEX idx_status (status),
    INDEX idx_order_date (order_created_at)
);

-- Create favorites table
CREATE TABLE favs (
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, event_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
);

-- Create bookings table (for the new booking system)
-- Note: event_id is VARCHAR because events are stored in JSON file, not in MySQL
-- Event details (title, location, date) are stored directly in bookings for display
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id VARCHAR(255) NOT NULL,
    event_title VARCHAR(500),
    event_location VARCHAR(500),
    event_start_date DATETIME,
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    booking_date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_event_id (event_id),
    INDEX idx_status (status),
    INDEX idx_booking_date (booking_date)
);

-- Insert sample users (password is BCrypt hash of 'password123')
INSERT INTO users (name, email, password, company, city, country, phone) VALUES
('Alice Johnson', 'alice.johnson@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Tech Corp', 'New York', 'USA', '+1-555-0101'),
('Bob Smith', 'bob.smith@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Design Studio', 'Los Angeles', 'USA', '+1-555-0102'),
('Charlie Brown', 'charlie.brown@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Marketing Inc', 'Chicago', 'USA', '+1-555-0103'),
('Diana Prince', 'diana.prince@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Wonder Corp', 'Themyscira', 'Greece', '+30-555-0104'),
('Ethan Hunt', 'ethan.hunt@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'IMF', 'Langley', 'USA', '+1-555-0105'),
('Fiona Gallagher', 'fiona.gallagher@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Gallagher Ltd', 'Chicago', 'USA', '+1-555-0106'),
('George Miller', 'george.miller@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Film Studio', 'Sydney', 'Australia', '+61-555-0107'),
('Hannah Lee', 'hannah.lee@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Tech Solutions', 'Seoul', 'South Korea', '+82-555-0108'),
('Ian Wright', 'ian.wright@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Sports Media', 'London', 'UK', '+44-555-0109'),
('Jane Doe', 'jane.doe@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Generic Corp', 'Anytown', 'USA', '+1-555-0110'),
('Kevin Hart', 'kevin.hart@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Comedy Central', 'Philadelphia', 'USA', '+1-555-0111'),
('Laura Palmer', 'laura.palmer@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Twin Peaks Corp', 'Twin Peaks', 'USA', '+1-555-0112'),
('Mike Ross', 'mike.ross@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Pearson Hardman', 'New York', 'USA', '+1-555-0113'),
('Nina Dobrev', 'nina.dobrev@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Vampire Diaries Inc', 'Mystic Falls', 'USA', '+1-555-0114'),
('Oscar Isaac', 'oscar.isaac@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Star Wars Studios', 'Guatemala City', 'Guatemala', '+502-555-0115'),
('Paula White', 'paula.white@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'White Consulting', 'Miami', 'USA', '+1-555-0116'),
('Quincy Adams', 'quincy.adams@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Adams Family Trust', 'Boston', 'USA', '+1-555-0117'),
('Rachel Green', 'rachel.green@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Central Perk Fashion', 'New York', 'USA', '+1-555-0118'),
('Steve Rogers', 'steve.rogers@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Avengers Inc', 'Brooklyn', 'USA', '+1-555-0119'),
('Tina Fey', 'tina.fey@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', '30 Rock Productions', 'New York', 'USA', '+1-555-0120'),
('testuser', 'test@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye7I7sJqjWJpGWJhLqAn.Z5s5QEyHHhq2', 'Test Company', 'Test City', 'Test Country', '+1-555-0121');

-- Insert sample events
INSERT INTO events (title, category, description, location, start_date, end_date, user_id) VALUES
('Spring Music Festival', 'Music', 'Annual spring music festival featuring local and international artists', 'Central Park, New York', '2025-05-15 10:00:00', '2025-05-17 23:00:00', 1),
('Tech Conference 2025', 'Technology', 'Latest trends in technology and innovation', 'Convention Center, San Francisco', '2025-06-20 09:00:00', '2025-06-22 18:00:00', 2),
('Food & Wine Expo', 'Food', 'Culinary experience with renowned chefs', 'Exhibition Hall, Chicago', '2025-07-10 12:00:00', '2025-07-12 20:00:00', 3),
('Art Gallery Opening', 'Art', 'Modern art exhibition featuring contemporary artists', 'Metropolitan Museum, New York', '2025-08-05 18:00:00', '2025-08-05 22:00:00', 4),
('Comedy Night', 'Entertainment', 'Stand-up comedy show with famous comedians', 'Comedy Club, Los Angeles', '2025-09-15 20:00:00', '2025-09-15 23:00:00', 5);

-- Insert sample tickets
INSERT INTO tickets (event_id, tk_types, price, quantity) VALUES
(1, 'General Admission', 75.00, 1000),
(1, 'VIP', 150.00, 100),
(2, 'Early Bird', 199.00, 500),
(2, 'Regular', 249.00, 800),
(2, 'Premium', 399.00, 200),
(3, 'Standard', 89.00, 600),
(3, 'Premium', 149.00, 200),
(4, 'General', 25.00, 300),
(5, 'Standard', 45.00, 200),
(5, 'VIP', 85.00, 50);

-- Display success message
SELECT 'Database setup completed successfully!' as status;
SELECT 'Default password for all users is: password123' as note;

-- Create MySQL user for testing
CREATE USER IF NOT EXISTS 'username'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON devop_db.* TO 'username'@'%';
FLUSH PRIVILEGES;

-- Display user creation message
SELECT 'MySQL user created: username/password' as user_info;
