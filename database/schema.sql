-- Voltix - MySQL 8 schema
-- Chạy: mysql -u root -p < database/schema.sql

CREATE DATABASE IF NOT EXISTS voltix CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE voltix;

-- ===== Người dùng =====
CREATE TABLE users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(15),
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('customer', 'staff', 'admin') NOT NULL DEFAULT 'customer',
    avatar_url    VARCHAR(500),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    receiver   VARCHAR(100) NOT NULL,
    phone      VARCHAR(15) NOT NULL,
    detail     VARCHAR(255) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ===== Sản phẩm =====
CREATE TABLE categories (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(50)  NOT NULL UNIQUE
);

CREATE TABLE brands (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL UNIQUE,
    logo_url VARCHAR(500)
);

CREATE TABLE products (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    brand_id    INT NOT NULL,
    name        VARCHAR(200) NOT NULL,
    description TEXT,
    price       INT NOT NULL CHECK (price >= 0),
    sale_price  INT NULL CHECK (sale_price >= 0),
    stock       INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url   VARCHAR(500),
    specs       JSON,               -- {"socket":"AM5","ram_type":"DDR5","tdp":65,...} dùng cho PC Builder
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (brand_id)    REFERENCES brands(id),
    INDEX idx_products_name (name)
);

CREATE TABLE product_images (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    url        VARCHAR(500) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ===== Giỏ hàng =====
CREATE TABLE cart_items (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    UNIQUE KEY uq_cart_user_product (user_id, product_id),
    FOREIGN KEY (user_id)    REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ===== Đơn hàng & thanh toán =====
CREATE TABLE orders (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT NOT NULL,
    receiver         VARCHAR(100) NOT NULL,   -- snapshot địa chỉ lúc đặt
    phone            VARCHAR(15)  NOT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    note             VARCHAR(255),
    total            INT NOT NULL,
    status           ENUM('pending', 'paid', 'confirmed', 'shipping', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    payment_method   ENUM('COD', 'VNPAY') NOT NULL,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_orders_created (created_at)
);

CREATE TABLE order_items (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price INT NOT NULL,                  -- giá tại thời điểm mua
    FOREIGN KEY (order_id)   REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE payments (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT NOT NULL,
    provider      ENUM('VNPAY') NOT NULL,
    txn_ref       VARCHAR(100) NOT NULL UNIQUE,  -- vnp_TxnRef
    amount        INT NOT NULL,
    status        ENUM('pending', 'success', 'failed') NOT NULL DEFAULT 'pending',
    response_code VARCHAR(10),
    paid_at       DATETIME,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- ===== Đánh giá =====
CREATE TABLE reviews (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    product_id INT NOT NULL,
    rating     TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    VARCHAR(1000),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_review_user_product (user_id, product_id),
    FOREIGN KEY (user_id)    REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ===== Chat tư vấn =====
CREATE TABLE conversations (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    staff_id    INT NULL,                     -- NULL: chưa có nhân viên nhận
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id)    REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE messages (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT NOT NULL,
    sender_id       INT NOT NULL,
    content         VARCHAR(2000) NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id)       REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_messages_conv (conversation_id, created_at)
);

-- ===== PC Builder =====
CREATE TABLE pc_builds (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    name       VARCHAR(100) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE pc_build_items (
    build_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL DEFAULT 1,
    PRIMARY KEY (build_id, product_id),
    FOREIGN KEY (build_id)   REFERENCES pc_builds(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);
