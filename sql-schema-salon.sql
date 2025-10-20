-- ================== DATABASE SELECTION ===================
CREATE DATABASE IF NOT EXISTS salon_platform;
USE salon_platform;

-- ================== CLEANUP ===================
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS service_photos;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS history;
DROP TABLE IF EXISTS payouts;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS saved_cards;
DROP TABLE IF EXISTS loyalty;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS carts;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS product_usage;
DROP TABLE IF EXISTS product_sales;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS notification_tracking;
DROP TABLE IF EXISTS notification_preferences;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS appointment_audit;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS staff_service;
DROP TABLE IF EXISTS staff_availability;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS service_categories;
DROP TABLE IF EXISTS main_categories;
DROP TABLE IF EXISTS salon_audit;
DROP TABLE IF EXISTS salon_admin;
DROP TABLE IF EXISTS salons;
DROP TABLE IF EXISTS auth;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS user_roles;

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- ================== CORE USERS =============================
-- ==========================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    profile_pic VARCHAR(255),
    user_role ENUM('customer', 'staff', 'owner', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name ENUM('customer','staff','owner','admin') UNIQUE NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE user_roles (
    user_role_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_role (user_id, role_id)
) ENGINE=InnoDB;

CREATE TABLE auth (
    auth_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(256) NOT NULL,
    last_login TIMESTAMP NULL,
    login_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================================
-- ================== SALON MANAGEMENT =======================
-- ==========================================================
CREATE TABLE salons (
    salon_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    description TEXT,
    status ENUM('pending', 'active', 'blocked') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE salon_admin (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    reviewed_by INT NULL,
    review_status ENUM('pending','approved','rejected','blocked') DEFAULT 'pending',
    license_number VARCHAR(50),
    license_doc VARCHAR(255),
    geo_verified BOOLEAN DEFAULT FALSE,
    deposit_paid BOOLEAN DEFAULT FALSE,
    rejected_reason TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE salon_audit (
  audit_id INT AUTO_INCREMENT PRIMARY KEY,
  salon_id INT NOT NULL,
  event_type ENUM('CREATED','APPROVED','REJECTED','BLOCKED','UPDATED','AUTO_ARCHIVED') NOT NULL,
  event_note TEXT,
  performed_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
  FOREIGN KEY (performed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE salon_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    tax_rate DECIMAL(5,2) DEFAULT 0.00,
    cancellation_policy TEXT,
    auto_complete_after INT DEFAULT 120,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    UNIQUE KEY unique_salon_setting (salon_id)
) ENGINE=InnoDB;

-- ==========================================================
-- ================== STAFF TABLES ===========================
-- ==========================================================
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'barber',
    specialization TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE staff_availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE staff_time_off (
    timeoff_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    reason VARCHAR(255),
    approved_by INT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_staff_timeoff_staff (staff_id),
    INDEX idx_staff_timeoff_date (start_datetime, end_datetime)
) ENGINE=InnoDB;

CREATE TABLE staff_attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    checkin_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    checkout_time DATETIME NULL,
    status ENUM('on_time','late','absent') DEFAULT 'on_time',
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    INDEX idx_staff_attendance_staff (staff_id),
    INDEX idx_staff_attendance_checkin (checkin_time)
) ENGINE=InnoDB;


-- ==========================================================
-- ================== SERVICES ==============================
-- ==========================================================
CREATE TABLE main_categories (
    main_category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE service_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    main_category_id INT NOT NULL,
    salon_id INT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_global BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (main_category_id) REFERENCES main_categories(main_category_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE SET NULL,
    UNIQUE KEY unique_category (name, main_category_id, salon_id)
) ENGINE=InnoDB;

CREATE TABLE services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    category_id INT NOT NULL,
    custom_name VARCHAR(100),
    duration INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES service_categories(category_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE staff_service (
    staff_service_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    service_id INT NOT NULL,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
    UNIQUE KEY unique_staff_service (staff_id, service_id)
) ENGINE=InnoDB;

-- ==========================================================
-- ================== APPOINTMENTS ===========================
-- ==========================================================
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    staff_id INT NULL,
    service_id INT NOT NULL,
    scheduled_time DATETIME NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('booked', 'completed', 'cancelled', 'no_show') DEFAULT 'booked',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE appointment_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    event_type ENUM('CREATED','UPDATED','CANCELLED','RESCHEDULED','STAFF_CHANGED') NOT NULL,
    event_note TEXT,
    performed_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE appointment_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    service_id INT NOT NULL,
    duration INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
    UNIQUE KEY unique_appt_service (appointment_id, service_id)
) ENGINE=InnoDB;



-- ==========================================================
-- ================== NOTIFICATIONS ==========================
-- ==========================================================
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notification_preferences (
    pref_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    quiet_hours_start TIME NULL,
    quiet_hours_end TIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notification_tracking (
    track_id INT AUTO_INCREMENT PRIMARY KEY,
    notification_id INT NOT NULL,
    delivery_method ENUM('email','sms','push'),
    delivered BOOLEAN DEFAULT FALSE,
    opened BOOLEAN DEFAULT FALSE,
    bounced BOOLEAN DEFAULT FALSE,
    delivered_at DATETIME NULL,
    FOREIGN KEY (notification_id) REFERENCES notifications(notification_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Notification to be sent table
CREATE TABLE notification_queue (
    queue_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    delivery_method ENUM('email','sms','push') DEFAULT 'email',
    scheduled_for DATETIME NOT NULL,
    sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_notif_queue_user (user_id),
    INDEX idx_notif_queue_schedule (scheduled_for)
) ENGINE=InnoDB;

-- ==========================================================
-- ================== PRODUCTS & INVENTORY ===================
-- ==========================================================
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    category ENUM('Hair','Skin','Nails','Other') DEFAULT 'Other',
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    reorder_level INT DEFAULT 5,
    sku VARCHAR(50) UNIQUE,
    supplier_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product_sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NULL,
    salon_id INT NOT NULL,
    quantity INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    sold_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product_usage (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_used INT NOT NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    salon_id INT NOT NULL,
    staff_id INT NULL,
    change_type ENUM('restock','sale','usage','adjustment','return','damage') NOT NULL,
    quantity_change INT NOT NULL,
    previous_stock INT DEFAULT 0,
    new_stock INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================================
-- ================== CARTS & ORDERS =========================
-- ==========================================================
CREATE TABLE carts (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    status ENUM('active','checked_out','abandoned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cart_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NULL,
    service_id INT NULL,
    quantity INT DEFAULT 1,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    type ENUM('product','service') NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE saved_cards (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    cardholder_name VARCHAR(100) NOT NULL,
    card_brand VARCHAR(50),
    last4 CHAR(4) NOT NULL,
    expiry_month INT NOT NULL,
    expiry_year INT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    token_reference VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('card','paypal','cash','wallet') DEFAULT 'card',
    payment_status ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
    transaction_ref VARCHAR(100),
    card_id INT NULL,
    appointment_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    FOREIGN KEY (card_id) REFERENCES saved_cards(card_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_id INT NULL,
    payment_status ENUM('pending','paid','failed','refunded') DEFAULT 'pending',
    order_status ENUM('processing','completed','cancelled') DEFAULT 'processing',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NULL,
    service_id INT NULL,
    quantity INT DEFAULT 1,
    price DECIMAL(10,2) NOT NULL,
    type ENUM('product','service') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ==========================================================
-- ================== OTHER TABLES ==========================
-- ==========================================================
CREATE TABLE loyalty (
    loyalty_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    points INT DEFAULT 0,
    last_earned TIMESTAMP NULL,
    last_redeemed TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payouts (
    payout_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    total_sales DECIMAL(10,2) DEFAULT 0.00,
    platform_fee DECIMAL(10,2) DEFAULT 0.00,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('stripe','paypal','manual') DEFAULT 'stripe',
    transaction_ref VARCHAR(100),
    payout_status ENUM('pending','processed','failed') DEFAULT 'pending',
    payout_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- History
-- =====================================================

CREATE TABLE history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    staff_id INT NOT NULL,
    appointment_id INT NOT NULL,
    service_id INT NOT NULL,
    visit_date DATE NOT NULL,
    service_name VARCHAR(255),
    price DECIMAL(10,2) DEFAULT 0.00,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- Review table
-- =====================================================

CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    staff_id INT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT,
    response TEXT,
    is_visible BOOLEAN DEFAULT TRUE,
    is_flagged BOOLEAN DEFAULT FALSE,
    flagged_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- Picture of Services Provided
-- =====================================================

CREATE TABLE service_photos (
    photo_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    user_id INT NOT NULL,
    staff_id INT NULL,
    service_id INT NULL,
    photo_type ENUM('before', 'after') NOT NULL,
    photo_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- CUSTOMER 
-- =====================================================

CREATE TABLE customer_check_in (
    checkin_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    user_id INT NOT NULL,
    checkin_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('arrived','late','no_show') DEFAULT 'arrived',
    notes TEXT,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_customer_checkin_user (user_id),
    INDEX idx_customer_checkin_appt (appointment_id)
) ENGINE=InnoDB;

CREATE TABLE customer_feedback_followups (
    followup_id INT AUTO_INCREMENT PRIMARY KEY,
    review_id INT NOT NULL,
    user_id INT NOT NULL,
    message_sent TEXT,
    response_received TEXT,
    followup_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (review_id) REFERENCES reviews(review_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_followup_user (user_id)
) ENGINE=InnoDB;

-- =====================================================
-- GENERAL AUDIT LOG (System-Wide)
-- =====================================================
CREATE TABLE audit_logs (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100),
    action ENUM('INSERT','UPDATE','DELETE'),
    record_id INT,
    user_id INT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_user (user_id)
) ENGINE=InnoDB;


-- =====================================================
-- WALLET & WALLET TRANSACTIONS
-- =====================================================
CREATE TABLE wallet (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_wallet_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE wallet_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    wallet_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type ENUM('credit','debit') NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallet(wallet_id) ON DELETE CASCADE,
    INDEX idx_wallet_txn_wallet (wallet_id)
) ENGINE=InnoDB;

-- =====================================================
-- PROMO CODES / DISCOUNTS
-- =====================================================
CREATE TABLE promo_codes (
    promo_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    discount_type ENUM('percentage','fixed') DEFAULT 'percentage',
    discount_value DECIMAL(10,2) NOT NULL,
    start_date DATE,
    end_date DATE,
    usage_limit INT DEFAULT 0,
    used_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(salon_id) ON DELETE SET NULL,
    INDEX idx_promo_salon (salon_id),
    INDEX idx_promo_dates (start_date, end_date)
) ENGINE=InnoDB;