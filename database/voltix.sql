-- Voltix - schema + dữ liệu mẫu (mật khẩu mọi tài khoản: 123456)
-- Chạy: mysql -u root -p < database/voltix.sql

CREATE DATABASE IF NOT EXISTS voltix CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE voltix;


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `addresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `receiver` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `detail` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_default` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;
INSERT INTO `addresses` VALUES (1,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',1),(2,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',1),(3,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',1),(4,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',1);
/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `brands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `brands` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logo_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `brands` WRITE;
/*!40000 ALTER TABLE `brands` DISABLE KEYS */;
INSERT INTO `brands` VALUES (1,'Intel',NULL),(2,'AMD',NULL),(3,'ASUS',NULL),(4,'MSI',NULL),(5,'GIGABYTE',NULL),(6,'ASRock',NULL),(7,'Kingston',NULL),(8,'Corsair',NULL),(9,'G.Skill',NULL),(10,'Samsung',NULL),(11,'WD',NULL),(12,'Crucial',NULL),(13,'Seasonic',NULL),(14,'Cooler Master',NULL),(15,'NZXT',NULL),(16,'Lian Li',NULL),(17,'Deepcool',NULL),(18,'Noctua',NULL);
/*!40000 ALTER TABLE `brands` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `cart_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `quantity` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cart_user_product` (`user_id`,`product_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cart_items` WRITE;
/*!40000 ALTER TABLE `cart_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `cart_items` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (1,'CPU','cpu'),(2,'Mainboard','mainboard'),(3,'RAM','ram'),(4,'Card đồ hoạ','vga'),(5,'SSD','ssd'),(6,'Nguồn','psu'),(7,'Vỏ case','case'),(8,'Tản nhiệt','cooler');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `staff_id` int DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `conversations_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `conversations_ibfk_2` FOREIGN KEY (`staff_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `conversations` WRITE;
/*!40000 ALTER TABLE `conversations` DISABLE KEYS */;
INSERT INTO `conversations` VALUES (1,3,2,'2026-10-18 15:48:27');
/*!40000 ALTER TABLE `conversations` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `conversation_id` int NOT NULL,
  `sender_id` int NOT NULL,
  `content` varchar(2000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `conversation_id` (`conversation_id`),
  KEY `sender_id` (`sender_id`),
  CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,1,3,'Chào shop, mình muốn build PC chơi game tầm 25 triệu thì nên chọn VGA nào ạ?',0,'2026-10-18 15:48:27'),(2,1,2,'Chào bạn! Tầm 25 triệu bạn nên chọn RTX 4060 Ti hoặc RX 7800 XT nếu ưu tiên 2K ạ.',1,'2026-10-18 15:48:27'),(3,1,3,'Vậy CPU đi kèm nên là i5-14400F hay Ryzen 5 7600 ạ?',0,'2026-10-18 15:48:27');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `product_id` int NOT NULL,
  `quantity` int NOT NULL,
  `unit_price` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `order_items` WRITE;
/*!40000 ALTER TABLE `order_items` DISABLE KEYS */;
INSERT INTO `order_items` VALUES (1,1,30,1,890000),(2,1,37,1,2290000),(3,2,16,2,1790000),(4,3,2,1,3990000),(5,3,25,2,6490000),(6,3,10,2,2690000),(7,4,45,2,2790000),(8,4,18,2,3590000),(9,5,32,2,1290000),(10,6,27,2,2190000),(11,7,5,1,5190000),(12,7,12,1,4190000),(13,7,35,1,3090000),(14,8,2,2,3990000),(15,8,45,2,2790000),(16,8,3,1,9490000),(17,9,21,2,7590000),(18,9,16,1,1790000),(19,10,29,2,1690000),(20,11,12,1,4190000),(21,11,16,2,1790000),(22,12,42,1,690000),(23,12,6,1,7290000),(24,12,26,2,13990000),(25,13,20,1,1090000),(26,14,43,2,2690000),(27,14,41,1,1990000),(28,14,35,2,3090000),(29,15,18,1,3590000),(30,16,16,2,1790000),(31,16,31,1,1690000),(32,16,8,1,2590000),(33,17,21,2,7590000),(34,17,22,1,10490000),(35,17,35,2,3090000),(36,18,33,1,1390000),(37,18,10,1,2690000),(38,19,8,2,2590000),(39,20,11,2,6990000),(40,20,34,2,2590000),(41,20,19,2,1590000),(42,21,21,2,7590000),(43,21,19,1,1590000),(44,21,45,1,2790000),(45,22,10,1,2690000),(46,22,7,2,10490000),(47,23,3,2,9490000),(48,24,10,2,2690000),(49,24,37,2,2290000),(50,25,44,1,490000),(51,25,25,1,6490000),(52,26,23,2,16490000),(53,26,28,1,4690000),(54,27,12,2,4190000),(55,27,36,1,4290000),(56,28,34,1,2590000),(57,28,26,2,13990000),(58,29,19,1,1590000),(59,30,28,2,4690000),(60,30,43,1,2690000),(61,31,24,2,30990000),(62,31,35,2,3090000),(63,32,35,1,3090000),(64,33,7,1,10490000),(65,34,25,2,6490000),(66,34,34,2,2590000),(67,35,39,2,990000),(68,35,27,2,2190000),(69,36,31,2,1690000),(70,36,13,2,4990000),(71,36,23,2,16490000),(72,37,16,1,1790000),(73,37,27,2,2190000),(74,37,2,2,3990000),(75,38,30,2,890000),(76,38,29,1,1690000),(77,38,2,1,3990000),(78,39,14,1,2290000),(79,39,10,1,2690000),(80,40,31,1,1690000),(81,41,28,2,4690000),(82,42,5,1,5190000),(83,42,36,1,4290000),(84,43,10,2,2690000),(85,44,22,2,10490000),(86,45,17,1,2690000),(87,45,23,1,16490000),(88,45,20,2,1090000);
/*!40000 ALTER TABLE `order_items` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `receiver` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shipping_address` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total` int NOT NULL,
  `status` enum('pending','paid','confirmed','shipping','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_method` enum('COD','VNPAY') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `ix_orders_created_at` (`created_at`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (1,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,3180000,'completed','COD','2026-09-28 13:48:28','2026-09-28 13:48:28'),(2,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,3580000,'completed','COD','2026-10-03 14:48:28','2026-10-03 14:48:28'),(3,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,22350000,'completed','VNPAY','2026-10-06 06:48:28','2026-10-06 06:48:28'),(4,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,12760000,'completed','VNPAY','2026-09-13 03:48:28','2026-09-13 03:48:28'),(5,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,2580000,'completed','VNPAY','2026-09-14 04:48:28','2026-09-14 04:48:28'),(6,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,4380000,'completed','COD','2026-09-13 09:48:28','2026-09-13 09:48:28'),(7,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,12470000,'shipping','COD','2026-09-13 06:48:28','2026-09-13 06:48:28'),(8,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,23050000,'confirmed','COD','2026-08-27 11:48:28','2026-08-27 11:48:28'),(9,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,16970000,'paid','COD','2026-08-30 08:48:28','2026-08-30 08:48:28'),(10,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,3380000,'pending','COD','2026-09-23 13:48:28','2026-09-23 13:48:28'),(11,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,7770000,'cancelled','COD','2026-08-28 08:48:28','2026-08-28 08:48:28'),(12,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,35960000,'completed','VNPAY','2026-10-17 13:48:28','2026-10-17 13:48:28'),(13,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,1090000,'completed','COD','2026-09-16 07:48:28','2026-09-16 07:48:28'),(14,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,13550000,'completed','COD','2026-09-10 10:48:28','2026-09-10 10:48:28'),(15,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,3590000,'completed','COD','2026-08-30 06:48:28','2026-08-30 06:48:28'),(16,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,7860000,'completed','COD','2026-10-10 04:48:28','2026-10-10 04:48:28'),(17,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,31850000,'completed','VNPAY','2026-09-27 10:48:28','2026-09-27 10:48:28'),(18,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,4080000,'shipping','COD','2026-09-06 11:48:28','2026-09-06 11:48:28'),(19,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,5180000,'confirmed','VNPAY','2026-09-05 11:48:28','2026-09-05 11:48:28'),(20,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,22340000,'paid','VNPAY','2026-09-17 04:48:28','2026-09-17 04:48:28'),(21,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,19560000,'pending','VNPAY','2026-09-07 12:48:28','2026-09-07 12:48:28'),(22,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,23670000,'cancelled','COD','2026-09-18 03:48:28','2026-09-18 03:48:28'),(23,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,18980000,'completed','VNPAY','2026-09-11 09:48:28','2026-09-11 09:48:28'),(24,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,9960000,'completed','VNPAY','2026-08-27 06:48:28','2026-08-27 06:48:28'),(25,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,6980000,'completed','COD','2026-09-22 05:48:28','2026-09-22 05:48:28'),(26,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,37670000,'completed','COD','2026-09-21 11:48:28','2026-09-21 11:48:28'),(27,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,12670000,'completed','COD','2026-10-11 13:48:28','2026-10-11 13:48:28'),(28,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,30570000,'completed','COD','2026-09-02 11:48:28','2026-09-02 11:48:28'),(29,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,1590000,'shipping','COD','2026-09-15 09:48:28','2026-09-15 09:48:28'),(30,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,12070000,'confirmed','COD','2026-10-07 13:48:28','2026-10-07 13:48:28'),(31,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,68160000,'paid','COD','2026-09-26 11:48:28','2026-09-26 11:48:28'),(32,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,3090000,'pending','VNPAY','2026-08-26 11:48:28','2026-08-26 11:48:28'),(33,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,10490000,'cancelled','COD','2026-08-27 10:48:28','2026-08-27 10:48:28'),(34,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,18160000,'completed','VNPAY','2026-10-07 05:48:28','2026-10-07 05:48:28'),(35,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,6360000,'completed','VNPAY','2026-09-04 13:48:28','2026-09-04 13:48:28'),(36,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,46340000,'completed','VNPAY','2026-08-25 12:48:28','2026-08-25 12:48:28'),(37,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,14150000,'completed','VNPAY','2026-09-18 13:48:28','2026-09-18 13:48:28'),(38,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,7460000,'completed','VNPAY','2026-10-03 13:48:28','2026-10-03 13:48:28'),(39,5,'Lê Minh C','0923456789','8 Lê Duẩn, Hải Châu, Đà Nẵng',NULL,4980000,'completed','COD','2026-08-27 05:48:28','2026-08-27 05:48:28'),(40,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,1690000,'shipping','VNPAY','2026-08-22 15:48:28','2026-08-22 15:48:28'),(41,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,9380000,'confirmed','COD','2026-10-12 04:48:28','2026-10-12 04:48:28'),(42,3,'Nguyễn Văn A','0901234567','12 Nguyễn Huệ, Q.1, TP.HCM',NULL,9480000,'paid','COD','2026-10-17 12:48:28','2026-10-17 12:48:28'),(43,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,5380000,'pending','COD','2026-09-02 06:48:28','2026-09-02 06:48:28'),(44,6,'Phạm Quốc D','0934567890','102 Hùng Vương, Ninh Kiều, Cần Thơ',NULL,20980000,'cancelled','VNPAY','2026-10-10 13:48:28','2026-10-10 13:48:28'),(45,4,'Trần Thị B','0912345678','45 Trần Duy Hưng, Cầu Giấy, Hà Nội',NULL,21360000,'completed','VNPAY','2026-09-03 13:48:28','2026-09-03 13:48:28');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `provider` enum('VNPAY') COLLATE utf8mb4_unicode_ci NOT NULL,
  `txn_ref` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` int NOT NULL,
  `status` enum('pending','success','failed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `response_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `txn_ref` (`txn_ref`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,3,'VNPAY','3-seed',22350000,'success','00','2026-10-06 06:48:28','2026-10-18 15:48:27'),(2,4,'VNPAY','4-seed',12760000,'success','00','2026-09-13 03:48:28','2026-10-18 15:48:27'),(3,5,'VNPAY','5-seed',2580000,'success','00','2026-09-14 04:48:28','2026-10-18 15:48:27'),(4,12,'VNPAY','12-seed',35960000,'success','00','2026-10-17 13:48:28','2026-10-18 15:48:27'),(5,17,'VNPAY','17-seed',31850000,'success','00','2026-09-27 10:48:28','2026-10-18 15:48:27'),(6,19,'VNPAY','19-seed',5180000,'success','00','2026-09-05 11:48:28','2026-10-18 15:48:27'),(7,20,'VNPAY','20-seed',22340000,'success','00','2026-09-17 04:48:28','2026-10-18 15:48:27'),(8,23,'VNPAY','23-seed',18980000,'success','00','2026-09-11 09:48:28','2026-10-18 15:48:27'),(9,24,'VNPAY','24-seed',9960000,'success','00','2026-08-27 06:48:28','2026-10-18 15:48:27'),(10,34,'VNPAY','34-seed',18160000,'success','00','2026-10-07 05:48:28','2026-10-18 15:48:27'),(11,35,'VNPAY','35-seed',6360000,'success','00','2026-09-04 13:48:28','2026-10-18 15:48:27'),(12,36,'VNPAY','36-seed',46340000,'success','00','2026-08-25 12:48:28','2026-10-18 15:48:27'),(13,37,'VNPAY','37-seed',14150000,'success','00','2026-09-18 13:48:28','2026-10-18 15:48:27'),(14,38,'VNPAY','38-seed',7460000,'success','00','2026-10-03 13:48:28','2026-10-18 15:48:27'),(15,40,'VNPAY','40-seed',1690000,'success','00','2026-08-22 15:48:28','2026-10-18 15:48:27'),(16,45,'VNPAY','45-seed',21360000,'success','00','2026-09-03 13:48:28','2026-10-18 15:48:27');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `pc_build_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pc_build_items` (
  `build_id` int NOT NULL,
  `product_id` int NOT NULL,
  `quantity` int NOT NULL,
  PRIMARY KEY (`build_id`,`product_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `pc_build_items_ibfk_1` FOREIGN KEY (`build_id`) REFERENCES `pc_builds` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pc_build_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `pc_build_items` WRITE;
/*!40000 ALTER TABLE `pc_build_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `pc_build_items` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `pc_builds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pc_builds` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `pc_builds_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `pc_builds` WRITE;
/*!40000 ALTER TABLE `pc_builds` DISABLE KEYS */;
/*!40000 ALTER TABLE `pc_builds` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `product_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_images` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `product_images` WRITE;
/*!40000 ALTER TABLE `product_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_images` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category_id` int NOT NULL,
  `brand_id` int NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` int NOT NULL,
  `sale_price` int DEFAULT NULL,
  `stock` int NOT NULL,
  `image_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `specs` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  KEY `brand_id` (`brand_id`),
  KEY `ix_products_name` (`name`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,1,1,'Intel Core i3-14100F','4 nhân 8 luồng, xung tối đa 4.7GHz, lựa chọn tiết kiệm cho PC văn phòng và gaming nhẹ.',2590000,NULL,30,'/static/products/cpu-intel.jpg','{\"tdp\": 58, \"igpu\": false, \"cores\": 4, \"socket\": \"LGA1700\", \"threads\": 8}',1,'2026-09-02 15:48:27'),(2,1,1,'Intel Core i5-14400F','10 nhân 16 luồng, xung tối đa 4.7GHz. CPU gaming quốc dân phân khúc tầm trung.',4290000,3990000,25,'/static/products/cpu-intel.jpg','{\"tdp\": 65, \"igpu\": false, \"cores\": 10, \"socket\": \"LGA1700\", \"threads\": 16}',1,'2026-09-03 15:48:27'),(3,1,1,'Intel Core i7-14700K','20 nhân 28 luồng, xung 5.6GHz, mở khoá ép xung, mạnh cho cả game và đồ hoạ.',9890000,9490000,10,'/static/products/cpu-intel.jpg','{\"tdp\": 125, \"igpu\": true, \"cores\": 20, \"socket\": \"LGA1700\", \"threads\": 28}',1,'2026-09-04 15:48:27'),(4,1,1,'Intel Core i9-14900K','24 nhân 32 luồng, xung tối đa 6.0GHz – CPU desktop mạnh nhất của Intel thế hệ 14.',14490000,NULL,4,'/static/products/cpu-intel.jpg','{\"tdp\": 125, \"igpu\": true, \"cores\": 24, \"socket\": \"LGA1700\", \"threads\": 32}',1,'2026-09-05 15:48:27'),(5,1,2,'AMD Ryzen 5 7600','6 nhân 12 luồng, kiến trúc Zen 4, hỗ trợ DDR5 và PCIe 5.0.',5190000,NULL,18,'/static/products/cpu-amd.jpg','{\"tdp\": 65, \"igpu\": true, \"cores\": 6, \"socket\": \"AM5\", \"threads\": 12}',1,'2026-09-06 15:48:27'),(6,1,2,'AMD Ryzen 7 7700X','8 nhân 16 luồng, xung 5.4GHz, hiệu năng đơn nhân rất mạnh.',7690000,7290000,12,'/static/products/cpu-amd.jpg','{\"tdp\": 105, \"igpu\": true, \"cores\": 8, \"socket\": \"AM5\", \"threads\": 16}',1,'2026-09-07 15:48:27'),(7,1,2,'AMD Ryzen 7 7800X3D','8 nhân 16 luồng với 3D V-Cache 96MB – CPU chơi game hàng đầu.',10990000,10490000,7,'/static/products/cpu-amd.jpg','{\"tdp\": 120, \"igpu\": true, \"cores\": 8, \"socket\": \"AM5\", \"threads\": 16}',1,'2026-09-08 15:48:27'),(8,1,2,'AMD Ryzen 5 5600','6 nhân 12 luồng, nền tảng AM4 giá tốt, dùng RAM DDR4.',2790000,2590000,22,'/static/products/cpu-amd.jpg','{\"tdp\": 65, \"igpu\": false, \"cores\": 6, \"socket\": \"AM4\", \"threads\": 12}',1,'2026-09-09 15:48:27'),(9,2,3,'ASUS PRIME B760M-A WIFI D4','Chipset B760, hỗ trợ DDR4, WiFi 6, 2 khe M.2.',3490000,NULL,12,'/static/products/mainboard.jpg','{\"form\": \"mATX\", \"socket\": \"LGA1700\", \"ram_type\": \"DDR4\"}',1,'2026-09-10 15:48:27'),(10,2,4,'MSI PRO B760M-P DDR5','Chipset B760, DDR5, thiết kế tối giản, giá tốt.',2890000,2690000,15,'/static/products/mainboard.jpg','{\"form\": \"mATX\", \"socket\": \"LGA1700\", \"ram_type\": \"DDR5\"}',1,'2026-09-11 15:48:27'),(11,2,5,'GIGABYTE Z790 AORUS ELITE AX','Chipset Z790 cho CPU K, VRM 16+1+2 pha, WiFi 6E, PCIe 5.0.',6990000,NULL,6,'/static/products/mainboard.jpg','{\"form\": \"ATX\", \"socket\": \"LGA1700\", \"ram_type\": \"DDR5\"}',1,'2026-09-12 15:48:27'),(12,2,4,'MSI B650M GAMING PLUS WIFI','Chipset B650 cho Ryzen 7000, DDR5, WiFi 6E.',4190000,NULL,9,'/static/products/mainboard.jpg','{\"form\": \"mATX\", \"socket\": \"AM5\", \"ram_type\": \"DDR5\"}',1,'2026-09-13 15:48:27'),(13,2,3,'ASUS TUF GAMING B650-PLUS WIFI','Độ bền chuẩn quân đội, VRM 12+2 pha, 3 khe M.2.',5290000,4990000,8,'/static/products/mainboard.jpg','{\"form\": \"ATX\", \"socket\": \"AM5\", \"ram_type\": \"DDR5\"}',1,'2026-09-14 15:48:27'),(14,2,6,'ASRock B550M Pro4','Chipset B550 cho Ryzen AM4, PCIe 4.0, 2 khe M.2.',2290000,NULL,14,'/static/products/mainboard.jpg','{\"form\": \"mATX\", \"socket\": \"AM4\", \"ram_type\": \"DDR4\"}',1,'2026-09-15 15:48:27'),(15,3,7,'Kingston Fury Beast 16GB (2x8GB) DDR4 3200','Kit RAM 16GB bus 3200MHz, tản nhiệt nhôm.',1090000,NULL,40,'/static/products/ram.jpg','{\"speed\": 3200, \"ram_type\": \"DDR4\", \"capacity_gb\": 16}',1,'2026-09-16 15:48:27'),(16,3,8,'Corsair Vengeance LPX 32GB (2x16GB) DDR4 3200','Kit 32GB DDR4 cấu hình thấp, tương thích tốt.',1890000,1790000,25,'/static/products/ram.jpg','{\"speed\": 3200, \"ram_type\": \"DDR4\", \"capacity_gb\": 32}',1,'2026-09-17 15:48:27'),(17,3,8,'Corsair Vengeance 32GB (2x16GB) DDR5 6000','Kit DDR5 32GB, hỗ trợ Intel XMP 3.0 và AMD EXPO.',2890000,2690000,22,'/static/products/ram.jpg','{\"speed\": 6000, \"ram_type\": \"DDR5\", \"capacity_gb\": 32}',1,'2026-09-18 15:48:27'),(18,3,9,'G.Skill Trident Z5 RGB 32GB (2x16GB) DDR5 6400','RAM DDR5 cao cấp, LED RGB, bus 6400MHz.',3590000,NULL,10,'/static/products/ram.jpg','{\"speed\": 6400, \"ram_type\": \"DDR5\", \"capacity_gb\": 32}',1,'2026-09-19 15:48:27'),(19,3,7,'Kingston Fury Beast 16GB (2x8GB) DDR5 5600','Kit DDR5 16GB giá tốt cho PC đời mới.',1590000,NULL,30,'/static/products/ram.jpg','{\"speed\": 5600, \"ram_type\": \"DDR5\", \"capacity_gb\": 16}',1,'2026-09-20 15:48:27'),(20,3,9,'G.Skill Ripjaws V 16GB (2x8GB) DDR4 3600','Bus 3600MHz, tối ưu cho Ryzen AM4.',1190000,1090000,3,'/static/products/ram.jpg','{\"speed\": 3600, \"ram_type\": \"DDR4\", \"capacity_gb\": 16}',1,'2026-09-21 15:48:27'),(21,4,5,'GIGABYTE RTX 4060 WINDFORCE OC 8GB','RTX 4060, DLSS 3, chơi tốt Full HD.',7990000,7590000,15,'/static/products/vga-gigabyte.jpg','{\"tdp\": 115, \"vram_gb\": 8}',1,'2026-09-22 15:48:27'),(22,4,3,'ASUS Dual RTX 4060 Ti 8GB','RTX 4060 Ti, tản 2 quạt Axial-tech, chơi tốt 1080p/1440p.',10490000,NULL,9,'/static/products/vga-nvidia.jpg','{\"tdp\": 160, \"vram_gb\": 8}',1,'2026-09-23 15:48:27'),(23,4,4,'MSI RTX 4070 SUPER VENTUS 2X 12GB','RTX 4070 SUPER 12GB, chơi mượt 2K max setting.',16990000,16490000,6,'/static/products/vga-nvidia.jpg','{\"tdp\": 220, \"vram_gb\": 12}',1,'2026-09-24 15:48:27'),(24,4,3,'ASUS TUF RTX 4080 SUPER 16GB','RTX 4080 SUPER, chơi 4K, tản nhiệt TUF siêu bền.',30990000,NULL,3,'/static/products/vga-nvidia.jpg','{\"tdp\": 320, \"vram_gb\": 16}',1,'2026-09-25 15:48:27'),(25,4,5,'GIGABYTE Radeon RX 7600 GAMING OC 8GB','RX 7600, hiệu năng/giá tốt cho game Full HD.',6890000,6490000,11,'/static/products/vga-amd.jpg','{\"tdp\": 165, \"vram_gb\": 8}',1,'2026-09-26 15:48:27'),(26,4,6,'ASRock Radeon RX 7800 XT Challenger 16GB','RX 7800 XT 16GB VRAM, mạnh ở độ phân giải 2K.',13990000,NULL,5,'/static/products/vga-amd.jpg','{\"tdp\": 263, \"vram_gb\": 16}',1,'2026-09-27 15:48:27'),(27,5,10,'Samsung 990 EVO 1TB NVMe','Đọc 5000MB/s, ghi 4200MB/s.',2190000,NULL,30,'/static/products/ssd.jpg','{\"interface\": \"PCIe 4.0\", \"capacity_gb\": 1000}',1,'2026-09-28 15:48:27'),(28,5,10,'Samsung 990 PRO 2TB NVMe','Đọc 7450MB/s, SSD PCIe 4.0 hàng đầu.',4990000,4690000,12,'/static/products/ssd.jpg','{\"interface\": \"PCIe 4.0\", \"capacity_gb\": 2000}',1,'2026-09-29 15:48:27'),(29,5,11,'WD Black SN770 1TB NVMe','Đọc 5150MB/s, tối ưu cho game.',1890000,1690000,20,'/static/products/ssd.jpg','{\"interface\": \"PCIe 4.0\", \"capacity_gb\": 1000}',1,'2026-09-30 15:48:27'),(30,5,7,'Kingston NV2 500GB NVMe','SSD NVMe giá rẻ, đọc 3500MB/s.',890000,NULL,45,'/static/products/ssd.jpg','{\"interface\": \"PCIe 4.0\", \"capacity_gb\": 500}',1,'2026-10-01 15:48:27'),(31,5,12,'Crucial P3 Plus 1TB NVMe','Đọc 5000MB/s, bảo hành 5 năm.',1690000,NULL,2,'/static/products/ssd.jpg','{\"interface\": \"PCIe 4.0\", \"capacity_gb\": 1000}',1,'2026-10-02 15:48:27'),(32,6,8,'Corsair CV550 550W 80 Plus Bronze','Nguồn 550W, đủ cho cấu hình tầm trung.',1290000,NULL,20,'/static/products/psu.jpg','{\"wattage\": 550}',1,'2026-10-03 15:48:27'),(33,6,14,'Cooler Master MWE 650 Bronze V2','Nguồn 650W 80 Plus Bronze, quạt 120mm êm.',1490000,1390000,18,'/static/products/psu.jpg','{\"wattage\": 650}',1,'2026-10-04 15:48:27'),(34,6,8,'Corsair RM750e 750W 80 Plus Gold','Full modular, ATX 3.0, hỗ trợ cáp 12VHPWR.',2590000,NULL,14,'/static/products/psu.jpg','{\"wattage\": 750}',1,'2026-10-05 15:48:27'),(35,6,13,'Seasonic FOCUS GX-850 850W Gold','Full modular, bảo hành 10 năm.',3290000,3090000,8,'/static/products/psu.jpg','{\"wattage\": 850}',1,'2026-10-06 15:48:27'),(36,6,4,'MSI MPG A1000G PCIE5 1000W Gold','1000W, ATX 3.0, dành cho cấu hình cao cấp.',4290000,NULL,5,'/static/products/psu.jpg','{\"wattage\": 1000}',1,'2026-10-07 15:48:27'),(37,7,15,'NZXT H5 Flow','Mid-tower, mặt lưới thông gió tốt, kèm 2 quạt.',2290000,NULL,10,'/static/products/case.jpg','{\"form\": \"ATX\"}',1,'2026-10-08 15:48:27'),(38,7,16,'Lian Li LANCOOL 216','Kèm 2 quạt 160mm phía trước, luồng gió cực tốt.',2490000,2290000,8,'/static/products/case.jpg','{\"form\": \"ATX\"}',1,'2026-10-09 15:48:27'),(39,7,14,'Cooler Master MasterBox Q300L','Case nhỏ gọn mATX, giá rẻ.',990000,NULL,25,'/static/products/case.jpg','{\"form\": \"mATX\"}',1,'2026-10-10 15:48:27'),(40,7,8,'Corsair 4000D Airflow','Case bán chạy nhất của Corsair, đi dây gọn gàng.',2390000,NULL,0,'/static/products/case-corsair.jpg','{\"form\": \"ATX\"}',1,'2026-10-11 15:48:27'),(41,7,17,'Deepcool CH560 Digital','Màn hình hiển thị nhiệt độ, kèm 4 quạt ARGB.',2190000,1990000,7,'/static/products/case.jpg','{\"form\": \"ATX\"}',1,'2026-10-12 15:48:27'),(42,8,17,'Deepcool AK400','Tản khí 4 ống đồng, tản tốt CPU 220W.',690000,NULL,35,'/static/products/cooler-air.jpg','{\"type\": \"air\", \"sockets\": [\"LGA1700\", \"AM5\", \"AM4\"]}',1,'2026-10-13 15:48:27'),(43,8,18,'Noctua NH-D15','Tản khí tháp đôi huyền thoại, cực êm.',2690000,NULL,6,'/static/products/cooler-air.jpg','{\"type\": \"air\", \"sockets\": [\"LGA1700\", \"AM5\", \"AM4\"]}',1,'2026-10-14 15:48:27'),(44,8,14,'Cooler Master Hyper 212 Black','Tản khí phổ thông, dễ lắp.',590000,490000,28,'/static/products/cooler-air.jpg','{\"type\": \"air\", \"sockets\": [\"LGA1700\", \"AM4\"]}',1,'2026-10-15 15:48:27'),(45,8,15,'NZXT Kraken 240','Tản nước AIO 240mm, màn hình LCD trên block.',2990000,2790000,9,'/static/products/cooler-aio.jpg','{\"type\": \"aio\", \"sockets\": [\"LGA1700\", \"AM5\", \"AM4\"]}',1,'2026-10-16 15:48:27'),(46,8,8,'Corsair iCUE H150i ELITE 360','Tản nước 360mm, 3 quạt RGB, cho CPU cao cấp.',4590000,NULL,4,'/static/products/cooler-aio.jpg','{\"type\": \"aio\", \"sockets\": [\"LGA1700\", \"AM5\", \"AM4\"]}',1,'2026-10-17 15:48:27');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `rating` smallint NOT NULL,
  `comment` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_review_user_product` (`user_id`,`product_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `reviews` WRITE;
/*!40000 ALTER TABLE `reviews` DISABLE KEYS */;
INSERT INTO `reviews` VALUES (1,5,30,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(2,5,37,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(3,4,16,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(4,4,2,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(5,4,25,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(6,4,10,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(7,4,45,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(8,4,18,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(9,3,32,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(10,6,27,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(11,5,42,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(12,5,6,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(13,5,26,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(14,6,20,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(15,3,43,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(16,3,41,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(17,3,35,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(18,5,18,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(19,5,16,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(20,5,31,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(21,5,8,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(22,6,21,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(23,6,22,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(24,6,35,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(25,4,3,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(26,6,10,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(27,6,37,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(28,4,44,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(29,4,23,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(30,4,28,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(31,6,12,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(32,6,36,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(33,6,34,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(34,6,26,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(35,4,34,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(36,3,39,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(37,3,27,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(38,6,31,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(39,6,13,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(40,6,23,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(41,3,16,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(42,3,2,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(43,5,29,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(44,5,2,3,'Ổn trong tầm giá.','2026-10-18 15:48:27'),(45,5,14,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(46,5,10,5,'Hàng chính hãng, đóng gói cẩn thận, giao nhanh!','2026-10-18 15:48:27'),(47,4,17,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27'),(48,4,20,4,'Sản phẩm tốt, đúng mô tả.','2026-10-18 15:48:27');
/*!40000 ALTER TABLE `reviews` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('customer','staff','admin') COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Quản trị viên','admin@voltix.vn','0900000001','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','admin',NULL,1,'2026-10-18 15:48:27'),(2,'Nhân viên tư vấn','staff@voltix.vn','0900000002','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','staff',NULL,1,'2026-10-18 15:48:27'),(3,'Nguyễn Văn A','customer@voltix.vn','0901234567','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','customer',NULL,1,'2026-10-18 15:48:27'),(4,'Trần Thị B','tranthib@gmail.com','0912345678','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','customer',NULL,1,'2026-10-18 15:48:27'),(5,'Lê Minh C','leminhc@gmail.com','0923456789','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','customer',NULL,1,'2026-10-18 15:48:27'),(6,'Phạm Quốc D','phamquocd@gmail.com','0934567890','$2b$12$y/pz9/kmx6nqkhwmxsHVgeBArguSLKRFur60perve1VzIGsvQSV4G','customer',NULL,1,'2026-10-18 15:48:27');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

