-- Initialize Concert Platform Database
USE concert_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(255) UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(500),
    company VARCHAR(255),
    website VARCHAR(255),
    phone VARCHAR(50),
    address VARCHAR(500),
    city VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
    event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    location VARCHAR(255),
    address VARCHAR(500),
    city VARCHAR(100),
    country VARCHAR(100),
    person_limit INT,
    phone VARCHAR(50),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    ticket_price DOUBLE,
    photo_id VARCHAR(255),
    photo_url VARCHAR(500),
    user_id BIGINT NOT NULL,
    organizer_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_event_organizer FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id VARCHAR(255) NOT NULL,
    event_title VARCHAR(255),
    event_location VARCHAR(255),
    event_start_date TIMESTAMP,
    quantity INT NOT NULL,
    total_price DOUBLE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    booking_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Insert sample user
INSERT IGNORE INTO users (name, email, password, username) VALUES 
('Test User', 'user1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user1');

-- Insert sample events
INSERT IGNORE INTO events (title, name, description, category, location, address, city, country, person_limit, phone, start_date, end_date, ticket_price, user_id) VALUES 
('Rock Concert 2025', 'Amazing Rock Night', 'Join us for an incredible rock concert featuring top bands', 'Music', 'Bangkok Arena', '123 Concert Hall St', 'Bangkok', 'Thailand', 1000, '+66-123-456789', '2025-12-15 19:00:00', '2025-12-15 23:00:00', 1500.00, 1),
('Jazz Festival', 'Smooth Jazz Evening', 'Relax with smooth jazz performances by renowned artists', 'Music', 'Jazz Club Central', '456 Music Ave', 'Bangkok', 'Thailand', 300, '+66-987-654321', '2025-12-20 20:00:00', '2025-12-20 24:00:00', 800.00, 1);