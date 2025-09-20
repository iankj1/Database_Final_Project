-- game_center_schema.sql

CREATE DATABASE IF NOT EXISTS `game_center` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `game_center`;

-- USERS: clients, staff, admins
CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('client','staff','admin') NOT NULL DEFAULT 'client',
    date_of_birth DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- GAMES catalog
CREATE TABLE IF NOT EXISTS games (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(160) NOT NULL UNIQUE, -- friendly identifier
    description TEXT,
    min_age TINYINT UNSIGNED DEFAULT 0,
    max_players TINYINT UNSIGNED DEFAULT 1,
    price_per_session DECIMAL(9,2) NOT NULL DEFAULT 0.00, -- currency
    duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- GAME_SESSIONS: scheduled time slots for a particular game
CREATE TABLE IF NOT EXISTS game_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    game_id INT UNSIGNED NOT NULL,
    session_code VARCHAR(50) NOT NULL UNIQUE, 
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    max_players TINYINT UNSIGNED NULL, 
    status ENUM('scheduled','ongoing','completed','cancelled') NOT NULL DEFAULT 'scheduled',
    created_by INT UNSIGNED NULL, -- staff/admin who created session
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (end_time > start_time)
) ENGINE=InnoDB;

-- PAYMENTS: record of payments
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method ENUM('cash','card','mpesa','online') NOT NULL,
    status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
    transaction_ref VARCHAR(120) NULL UNIQUE, 
    paid_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RECEIPTS: one-to-one with payments 
CREATE TABLE IF NOT EXISTS receipts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT UNSIGNED NOT NULL UNIQUE,
    receipt_number VARCHAR(100) NOT NULL UNIQUE,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- BOOKINGS: high-level booking record (can be for session or generic booking)
CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    booking_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('pending','confirmed','paid','cancelled','refunded') NOT NULL DEFAULT 'pending',
    payment_id BIGINT UNSIGNED NULL,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Many-to-many: bookings - games (a booking may include multiple games or sessions)
CREATE TABLE IF NOT EXISTS booking_items (
    booking_id BIGINT UNSIGNED NOT NULL,
    game_id INT UNSIGNED NOT NULL,
    quantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    unit_price DECIMAL(9,2) NOT NULL, -- capture price at time of booking
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
    PRIMARY KEY (booking_id, game_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- CARTS: each user can have one active cart; cart_items stores selections
CREATE TABLE IF NOT EXISTS carts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cart_items (
    cart_id BIGINT UNSIGNED NOT NULL,
    game_id INT UNSIGNED NOT NULL,
    quantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    unit_price DECIMAL(9,2) NOT NULL,
    PRIMARY KEY (cart_id, game_id),
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- SESSION ATTENDANCE: which users attended which sessions (many-to-many)
CREATE TABLE IF NOT EXISTS session_attendance (
    session_id BIGINT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    checked_in_at DATETIME NULL,
    role ENUM('player','guest','staff') NOT NULL DEFAULT 'player',
    PRIMARY KEY (session_id, user_id),
    FOREIGN KEY (session_id) REFERENCES game_sessions(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- SUPPORT MESSAGES
CREATE TABLE IF NOT EXISTS support_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('open','in_progress','resolved','closed') NOT NULL DEFAULT 'open',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- simple audit log for critical events (payments, refunds, bookings)
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_data JSON NULL,
    occurred_by INT UNSIGNED NULL,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (occurred_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Useful indexes to speed lookups (non-unique)
CREATE INDEX idx_games_available ON games(available);
CREATE INDEX idx_sessions_game_start ON game_sessions(game_id, start_time);
CREATE INDEX idx_payments_user_status ON payments(user_id, status);
CREATE INDEX idx_bookings_user_status ON bookings(user_id, status);
