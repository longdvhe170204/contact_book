DROP DATABASE IF EXISTS befschool;
CREATE DATABASE befschool;
USE befschool;

-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: befschool
-- ------------------------------------------------------
-- Server version	8.0.43

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

--
-- Table structure for table `assignments`
--

DROP TABLE IF EXISTS `assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assignments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `teacher_id` bigint DEFAULT NULL,
  `class_name` varchar(255) DEFAULT NULL,
  `description` text,
  `due_date` date DEFAULT NULL,
  `file_url` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assignments`
--

LOCK TABLES `assignments` WRITE;
/*!40000 ALTER TABLE `assignments` DISABLE KEYS */;
INSERT INTO `assignments` VALUES (1,4,'10A1','Bài tập về hàm số - chi tiết bài tập','2026-07-27',NULL,'Bài tập về hàm số','2026-07-20 07:48:21.620220','2026-07-20 07:48:21.620220');
INSERT INTO `assignments` VALUES (2,5,'10A1','Làm văn tả người thân - chi tiết bài tập','2026-07-25',NULL,'Làm văn tả người thân','2026-07-20 07:48:21.621220','2026-07-20 07:48:21.621220');
INSERT INTO `assignments` VALUES (3,6,'10A1','Unit 5 - Speaking exercises - chi tiết bài tập','2026-07-30',NULL,'Unit 5 - Speaking exercises','2026-07-20 07:48:21.621220','2026-07-20 07:48:21.621220');
/*!40000 ALTER TABLE `assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attendance`
--

DROP TABLE IF EXISTS `attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `teacher_id` bigint DEFAULT NULL,
  `date` date NOT NULL,
  `status` varchar(255) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attendance`
--

LOCK TABLES `attendance` WRITE;
/*!40000 ALTER TABLE `attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chat_messages`
--

DROP TABLE IF EXISTS `chat_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat_messages` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `receiver_id` bigint NOT NULL,
  `sender_id` bigint NOT NULL,
  `content` text NOT NULL,
  `timestamp` datetime(6) NOT NULL,
  `is_read` bit(1) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chat_messages`
--

LOCK TABLES `chat_messages` WRITE;
/*!40000 ALTER TABLE `chat_messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `chat_messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `class_memberships`
--

DROP TABLE IF EXISTS `class_memberships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_memberships` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `class_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `joined_date` date NOT NULL,
  `school_year` varchar(9) NOT NULL,
  `status` enum('ACTIVE','COMPLETED','REMOVED','TRANSFERRED') NOT NULL,
  `left_date` date DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `parent_name` varchar(255) DEFAULT NULL,
  `parent_phone` varchar(255) DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `employee_code` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_membership_student_status` (`student_id`,`status`),
  KEY `idx_membership_class_status` (`class_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `class_memberships`
--

LOCK TABLES `class_memberships` WRITE;
/*!40000 ALTER TABLE `class_memberships` DISABLE KEYS */;
/*!40000 ALTER TABLE `class_memberships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conduct`
--

DROP TABLE IF EXISTS `conduct`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conduct` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `teacher_id` bigint DEFAULT NULL,
  `comment` text,
  `conduct_rating` enum('Tốt','Khá','Trung Bình','Yếu') DEFAULT NULL,
  `month` int DEFAULT NULL,
  `year` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conduct`
--

LOCK TABLES `conduct` WRITE;
/*!40000 ALTER TABLE `conduct` DISABLE KEYS */;
/*!40000 ALTER TABLE `conduct` ENABLE KEYS */;
UNLOCK TABLES;


--
-- Table structure for table `fee_categories`
--

DROP TABLE IF EXISTS `fee_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_categories` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `billing_cycle` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `amount` decimal(38,2) DEFAULT NULL,
  `due_date_rule` varchar(50) DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fee_categories`
--

LOCK TABLES `fee_categories` WRITE;
/*!40000 ALTER TABLE `fee_categories` DISABLE KEYS */;
INSERT INTO `fee_categories` VALUES (1,'MONTHLY','Học phí cơ bản',3500000.00,'5','2026-07-20 07:48:20.467651');
INSERT INTO `fee_categories` VALUES (2,'MONTHLY','Phí ăn bán trú',1200000.00,'5','2026-07-20 07:48:20.470291');
INSERT INTO `fee_categories` VALUES (3,'YEARLY','Quỹ lớp',500000.00,'09-15','2026-07-20 07:48:20.473294');
INSERT INTO `fee_categories` VALUES (4,'YEARLY','Bảo hiểm y tế',850000.00,'09-15','2026-07-20 07:48:20.475294');
INSERT INTO `fee_categories` VALUES (5,'ONETIME','Đồng phục',1500000.00,'2026-08-30','2026-07-20 07:48:20.477295');
/*!40000 ALTER TABLE `fee_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fee_details`
--

DROP TABLE IF EXISTS `fee_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_details` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `fee_category_id` bigint DEFAULT NULL,
  `tuition_fee_id` bigint NOT NULL,
  `amount` decimal(38,2) NOT NULL,
  `due_date` datetime(6) NOT NULL,
  `name_snapshot` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKrcc4virtcaeombn3qm5s7ir4n` (`fee_category_id`),
  KEY `FKgtjqbk6gwmot8vt5rpcp4l3pj` (`tuition_fee_id`),
  CONSTRAINT `FKgtjqbk6gwmot8vt5rpcp4l3pj` FOREIGN KEY (`tuition_fee_id`) REFERENCES `tuition_fees` (`id`),
  CONSTRAINT `FKrcc4virtcaeombn3qm5s7ir4n` FOREIGN KEY (`fee_category_id`) REFERENCES `fee_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fee_details`
--

LOCK TABLES `fee_details` WRITE;
/*!40000 ALTER TABLE `fee_details` DISABLE KEYS */;
/*!40000 ALTER TABLE `fee_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fee_payments`
--

DROP TABLE IF EXISTS `fee_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_payments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tuition_fee_id` bigint NOT NULL,
  `amount_paid` decimal(38,2) NOT NULL,
  `payment_date` datetime(6) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `status` varchar(20) NOT NULL,
  `vnp_transaction_no` varchar(50) DEFAULT NULL,
  `vnp_txn_ref` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK57nr4hco8j17hwq052surwj28` (`tuition_fee_id`),
  CONSTRAINT `FK57nr4hco8j17hwq052surwj28` FOREIGN KEY (`tuition_fee_id`) REFERENCES `tuition_fees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fee_payments`
--

LOCK TABLES `fee_payments` WRITE;
/*!40000 ALTER TABLE `fee_payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `fee_payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grades`
--

DROP TABLE IF EXISTS `grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grades` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `teacher_id` bigint DEFAULT NULL,
  `semester` int NOT NULL,
  `average` double DEFAULT NULL,
  `cuoi_ky` double DEFAULT NULL,
  `giua_ky` double DEFAULT NULL,
  `tx15` text,
  `tx1tiet` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grades`
--

LOCK TABLES `grades` WRITE;
/*!40000 ALTER TABLE `grades` DISABLE KEYS */;
INSERT INTO `grades` VALUES (1,1,4,1,8.5,9,8.5,'[8.5,9.0,7.5]','[8.0,8.5]','2026-07-20 07:48:21.558358','2026-07-20 07:48:21.558358');
INSERT INTO `grades` VALUES (2,1,5,1,8.1,8.5,8,'[8.0,7.5,8.5]','[8.0,7.5]','2026-07-20 07:48:21.562354','2026-07-20 07:48:21.562354');
INSERT INTO `grades` VALUES (3,1,6,1,9.2,9.5,9,'[9.0,9.5,9.0]','[9.0,9.5]','2026-07-20 07:48:21.566700','2026-07-20 07:48:21.566700');
INSERT INTO `grades` VALUES (4,1,7,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.569705','2026-07-20 07:48:21.569705');
INSERT INTO `grades` VALUES (5,1,8,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.571704','2026-07-20 07:48:21.571704');
INSERT INTO `grades` VALUES (6,1,9,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.574705','2026-07-20 07:48:21.574705');
INSERT INTO `grades` VALUES (7,1,10,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.576705','2026-07-20 07:48:21.576705');
INSERT INTO `grades` VALUES (8,1,11,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.578705','2026-07-20 07:48:21.578705');
INSERT INTO `grades` VALUES (9,1,12,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.580707','2026-07-20 07:48:21.580707');
INSERT INTO `grades` VALUES (10,1,13,1,8,8,8,'[8.0,8.0,8.0]','[8.0,8.0]','2026-07-20 07:48:21.584221','2026-07-20 07:48:21.584221');
/*!40000 ALTER TABLE `grades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `category` varchar(255) DEFAULT NULL,
  `content` text,
  `date` varchar(255) DEFAULT NULL,
  `sender` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,'FEE','Học sinh vui lòng đóng học phí trước ngày 15/04.','02/03/2026','Ban Giám Hiệu','Thông báo đóng học phí học kỳ 2','2026-07-20 07:48:21.611220','2026-07-20 07:48:21.611220');
INSERT INTO `notifications` VALUES (2,'IMPORTANT','Trường nghỉ học để kỷ niệm.','08/03/2026','Ban Giám Hiệu','Thông báo nghỉ học ngày 08/03','2026-07-20 07:48:21.612220','2026-07-20 07:48:21.612220');
INSERT INTO `notifications` VALUES (3,'SCHOOL','Kết quả đã được đăng.','10/03/2026','Phòng Giáo Vụ','Kết quả kiểm tra giữa kỳ','2026-07-20 07:48:21.612220','2026-07-20 07:48:21.612220');
INSERT INTO `notifications` VALUES (4,'SCHOOL','Tham gia đông đủ.','20/11/2025','Ban Tổ Chức','Hội thi văn nghệ chào mừng 20/11','2026-07-20 07:48:21.613221','2026-07-20 07:48:21.613221');
INSERT INTO `notifications` VALUES (5,'IMPORTANT','Quy định mới về đồng phục.','01/02/2026','Ban Giám Hiệu','Thông báo về đồng phục học sinh','2026-07-20 07:48:21.614220','2026-07-20 07:48:21.614220');
INSERT INTO `notifications` VALUES (6,'IMPORTANT','Lịch thi được cập nhật.','15/04/2026','Phòng Giáo Vụ','Lịch thi học kỳ 2','2026-07-20 07:48:21.614220','2026-07-20 07:48:21.614220');
INSERT INTO `notifications` VALUES (7,'SCHOOL','Các hoạt động sẽ diễn ra.','05/03/2026','Ban Học Sinh','Hoạt động ngoại khóa tháng 3','2026-07-20 07:48:21.615225','2026-07-20 07:48:21.615225');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` enum('ADMIN','STUDENT','TEACHER') NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_ofx66keruapi6vyqpv6f2or37` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'STUDENT','Student account','2026-07-20 07:48:20.508834','2026-07-20 07:48:20.508834');
INSERT INTO `roles` VALUES (2,'TEACHER','Teacher account','2026-07-20 07:48:20.513393','2026-07-20 07:48:20.513393');
INSERT INTO `roles` VALUES (3,'ADMIN','Admin account','2026-07-20 07:48:20.516377','2026-07-20 07:48:20.516377');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schedules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `class_id` bigint DEFAULT NULL,
  `subject_id` bigint DEFAULT NULL,
  `teacher_id` bigint DEFAULT NULL,
  `day_of_week` int NOT NULL,
  `end_time` varchar(255) DEFAULT NULL,
  `period` varchar(255) DEFAULT NULL,
  `room_name` varchar(255) DEFAULT NULL,
  `school_year` varchar(255) DEFAULT NULL,
  `semester` int DEFAULT NULL,
  `start_time` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_schedule_class_slot` (`class_id`,`school_year`,`semester`,`day_of_week`,`period`),
  KEY `idx_schedule_teacher_slot` (`teacher_id`,`school_year`,`semester`,`day_of_week`,`period`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedules`
--

LOCK TABLES `schedules` WRITE;
/*!40000 ALTER TABLE `schedules` DISABLE KEYS */;
INSERT INTO `schedules` VALUES (1,1,NULL,4,0,'07:45','1','Phòng 301','2026-2027',1,'07:00','2026-07-20 07:48:21.591221','2026-07-20 07:48:21.591221');
INSERT INTO `schedules` VALUES (2,1,NULL,5,0,'08:35','2','Phòng 302','2026-2027',1,'07:50','2026-07-20 07:48:21.592220','2026-07-20 07:48:21.592220');
INSERT INTO `schedules` VALUES (3,1,NULL,6,0,'09:25','3','Phòng 303','2026-2027',1,'08:40','2026-07-20 07:48:21.593220','2026-07-20 07:48:21.593220');
INSERT INTO `schedules` VALUES (4,1,NULL,7,0,'10:15','4','Phòng 304','2026-2027',1,'09:30','2026-07-20 07:48:21.594223','2026-07-20 07:48:21.594223');
INSERT INTO `schedules` VALUES (5,1,NULL,8,0,'11:05','5','Phòng 305','2026-2027',1,'10:20','2026-07-20 07:48:21.594223','2026-07-20 07:48:21.594223');
INSERT INTO `schedules` VALUES (6,1,NULL,9,1,'07:45','1','Phòng 201','2026-2027',1,'07:00','2026-07-20 07:48:21.595221','2026-07-20 07:48:21.595221');
INSERT INTO `schedules` VALUES (7,1,NULL,10,1,'08:35','2','Phòng 202','2026-2027',1,'07:50','2026-07-20 07:48:21.596222','2026-07-20 07:48:21.596222');
INSERT INTO `schedules` VALUES (8,1,NULL,11,1,'09:25','3','Phòng 203','2026-2027',1,'08:40','2026-07-20 07:48:21.597222','2026-07-20 07:48:21.597222');
INSERT INTO `schedules` VALUES (9,1,NULL,4,1,'10:15','4','Phòng 301','2026-2027',1,'09:30','2026-07-20 07:48:21.597222','2026-07-20 07:48:21.597222');
INSERT INTO `schedules` VALUES (10,1,NULL,5,2,'07:45','1','Phòng 302','2026-2027',1,'07:00','2026-07-20 07:48:21.598224','2026-07-20 07:48:21.598224');
INSERT INTO `schedules` VALUES (11,1,NULL,6,2,'08:35','2','Phòng 303','2026-2027',1,'07:50','2026-07-20 07:48:21.599225','2026-07-20 07:48:21.599225');
INSERT INTO `schedules` VALUES (12,1,NULL,12,2,'09:25','3','Sân bóng','2026-2027',1,'08:40','2026-07-20 07:48:21.600223','2026-07-20 07:48:21.600223');
INSERT INTO `schedules` VALUES (13,1,NULL,4,3,'07:45','1','Phòng 301','2026-2027',1,'07:00','2026-07-20 07:48:21.600223','2026-07-20 07:48:21.600223');
INSERT INTO `schedules` VALUES (14,1,NULL,7,3,'08:35','2','Phòng 304','2026-2027',1,'07:50','2026-07-20 07:48:21.601224','2026-07-20 07:48:21.601224');
INSERT INTO `schedules` VALUES (15,1,NULL,8,3,'09:25','3','Phòng 305','2026-2027',1,'08:40','2026-07-20 07:48:21.602224','2026-07-20 07:48:21.602224');
INSERT INTO `schedules` VALUES (16,1,NULL,13,3,'10:15','4','Phòng Lab','2026-2027',1,'09:30','2026-07-20 07:48:21.602224','2026-07-20 07:48:21.602224');
INSERT INTO `schedules` VALUES (17,1,NULL,5,4,'07:45','1','Phòng 302','2026-2027',1,'07:00','2026-07-20 07:48:21.603224','2026-07-20 07:48:21.603224');
INSERT INTO `schedules` VALUES (18,1,NULL,6,4,'08:35','2','Phòng 303','2026-2027',1,'07:50','2026-07-20 07:48:21.604220','2026-07-20 07:48:21.604220');
INSERT INTO `schedules` VALUES (19,1,NULL,14,4,'09:25','3','Phòng 306','2026-2027',1,'08:40','2026-07-20 07:48:21.605223','2026-07-20 07:48:21.605223');
/*!40000 ALTER TABLE `schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `school_classes`
--

DROP TABLE IF EXISTS `school_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_classes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `homeroom_teacher_id` bigint DEFAULT NULL,
  `grade_level` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `school_year` varchar(9) NOT NULL,
  `status` enum('ACTIVE','ARCHIVED','CLOSED') NOT NULL,
  `maximum_students` int DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_school_class_name_year` (`name`,`school_year`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `school_classes`
--

LOCK TABLES `school_classes` WRITE;
/*!40000 ALTER TABLE `school_classes` DISABLE KEYS */;
INSERT INTO `school_classes` VALUES (1,NULL,10,'10A1','2026-2027','ACTIVE',NULL,'2026-07-20 07:48:20.420118','2026-07-20 07:48:20.420118');
INSERT INTO `school_classes` VALUES (2,NULL,10,'10A2','2026-2027','ACTIVE',NULL,'2026-07-20 07:48:20.451646','2026-07-20 07:48:20.451646');
/*!40000 ALTER TABLE `school_classes` ENABLE KEYS */;
UNLOCK TABLES;


--
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subjects` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `description` text,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_aodt3utnw0lsov4k9ta88dbpr` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subjects`
--

LOCK TABLES `subjects` WRITE;
/*!40000 ALTER TABLE `subjects` DISABLE KEYS */;
INSERT INTO `subjects` VALUES (1,'Môn Toán','Toán','2026-07-20 07:48:20.521392','2026-07-20 07:48:20.521392');
INSERT INTO `subjects` VALUES (2,'Môn Văn','Văn','2026-07-20 07:48:20.528377','2026-07-20 07:48:20.528377');
INSERT INTO `subjects` VALUES (3,'Môn Anh Văn','Anh Văn','2026-07-20 07:48:20.529377','2026-07-20 07:48:20.529377');
INSERT INTO `subjects` VALUES (4,'Môn Vật Lý','Vật Lý','2026-07-20 07:48:20.530378','2026-07-20 07:48:20.530378');
INSERT INTO `subjects` VALUES (5,'Môn Hóa Học','Hóa Học','2026-07-20 07:48:20.530378','2026-07-20 07:48:20.530378');
INSERT INTO `subjects` VALUES (6,'Môn Sinh Học','Sinh Học','2026-07-20 07:48:20.531379','2026-07-20 07:48:20.531379');
INSERT INTO `subjects` VALUES (7,'Môn Lịch Sử','Lịch Sử','2026-07-20 07:48:20.532377','2026-07-20 07:48:20.532377');
INSERT INTO `subjects` VALUES (8,'Môn Địa Lý','Địa Lý','2026-07-20 07:48:20.533377','2026-07-20 07:48:20.533377');
INSERT INTO `subjects` VALUES (9,'Môn Thể Dục','Thể Dục','2026-07-20 07:48:20.533377','2026-07-20 07:48:20.533377');
INSERT INTO `subjects` VALUES (10,'Môn Tin Học','Tin Học','2026-07-20 07:48:20.534377','2026-07-20 07:48:20.534377');
INSERT INTO `subjects` VALUES (11,'Môn GDCD','GDCD','2026-07-20 07:48:20.535411','2026-07-20 07:48:20.535411');
/*!40000 ALTER TABLE `subjects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tuition_fees`
--

DROP TABLE IF EXISTS `tuition_fees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tuition_fees` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `status` enum('PAID','UNPAID') NOT NULL,
  `title` varchar(255) NOT NULL,
  `total_expected` decimal(38,2) NOT NULL,
  `collection_month` varchar(7) DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FKmljhy7ipcn1l190hqm5dm9ed3` (`student_id`),
  CONSTRAINT `FKmljhy7ipcn1l190hqm5dm9ed3` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tuition_fees`
--

LOCK TABLES `tuition_fees` WRITE;
/*!40000 ALTER TABLE `tuition_fees` DISABLE KEYS */;
/*!40000 ALTER TABLE `tuition_fees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_roles` (
  `user_id` bigint NOT NULL,
  `role_id` bigint NOT NULL,
  PRIMARY KEY (`role_id`,`user_id`),
  KEY `FKhfh9dx7w3ubf1co1vdev94g3f` (`user_id`),
  CONSTRAINT `FKh8ciramu9cc9q3qcqiv4ue8a6` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `FKhfh9dx7w3ubf1co1vdev94g3f` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,1);
INSERT INTO `user_roles` VALUES (2,1);
INSERT INTO `user_roles` VALUES (3,1);
INSERT INTO `user_roles` VALUES (4,2);
INSERT INTO `user_roles` VALUES (5,2);
INSERT INTO `user_roles` VALUES (6,2);
INSERT INTO `user_roles` VALUES (7,2);
INSERT INTO `user_roles` VALUES (8,2);
INSERT INTO `user_roles` VALUES (9,2);
INSERT INTO `user_roles` VALUES (10,2);
INSERT INTO `user_roles` VALUES (11,2);
INSERT INTO `user_roles` VALUES (12,2);
INSERT INTO `user_roles` VALUES (13,2);
INSERT INTO `user_roles` VALUES (14,2);
INSERT INTO `user_roles` VALUES (15,3);
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint DEFAULT NULL,
  `phone_number` varchar(10) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `is_active` bit(1) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  `parent_name` varchar(255) DEFAULT NULL,
  `parent_phone` varchar(10) DEFAULT NULL,
  `class_name` varchar(255) DEFAULT NULL,
  `employee_code` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_9q63snka3mdh91as4io72espi` (`phone_number`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,1,'0123456789',NULL,'2008-01-01','ly.phan72@fschool.edu.vn',_binary ' ','Phan Thị Lý','$2a$10$gOOOFMahAU3FfiJ7RtSzh.W/2lQY51KDmMABZ6oleC28JOxCiCV/u','2026-07-20 07:48:21.469138','2026-07-20 07:48:21.469138',NULL,NULL,'10A1',NULL,NULL);
INSERT INTO `users` VALUES (2,1,'0987654321',NULL,'2008-02-02','minh.nguyen15@fschool.edu.vn',_binary ' ','Nguyễn Hoàng Minh','$2a$10$nHwJo448aUffF93/cPtRj.EzAH/qByM4FOQpefWeYwRCT5HuF9Et6','2026-07-20 07:48:21.483651','2026-07-20 07:48:21.483651',NULL,NULL,'10A1',NULL,NULL);
INSERT INTO `users` VALUES (3,1,'0111222333',NULL,'2008-03-03','ngoc.tran88@fschool.edu.vn',_binary ' ','Trần Bảo Ngọc','$2a$10$r/k/QmtJYE8hWlhanZZ/WezwUUhP4.gNu5Iurn0t.oKvpz89MRYWC','2026-07-20 07:48:21.484650','2026-07-20 07:48:21.484650',NULL,NULL,'10A1',NULL,NULL);
INSERT INTO `users` VALUES (4,2,'0200000001',NULL,NULL,'trong.le45@fschool.edu.vn',_binary ' ','Lê Đình Trọng','$2a$10$R3OFYQ5hj9/BD8lYsybKX.MVWofxo/7o86bQA0G6PFQXKM3IaWeWO','2026-07-20 07:48:21.486430','2026-07-20 07:48:21.486430',NULL,NULL,NULL,'T001','Toán');
INSERT INTO `users` VALUES (5,2,'0200000002',NULL,NULL,'mai.pham23@fschool.edu.vn',_binary ' ','Phạm Thị Mai','$2a$10$MUHEv5lgvOaLWOtF9pqjcOfv6F2woMNByFJDCsxfCJPV7XLsutcNW','2026-07-20 07:48:21.487651','2026-07-20 07:48:21.487651',NULL,NULL,NULL,'T002','Ngữ văn');
INSERT INTO `users` VALUES (6,2,'0200000003',NULL,NULL,'dang.vu91@fschool.edu.vn',_binary ' ','Vũ Hải Đăng','$2a$10$pNDLwqP8K07GFpD40mfGb.AH15q4RcUjjelM6fNvFOBwhf7VoVoSW','2026-07-20 07:48:21.488160','2026-07-20 07:48:21.488160',NULL,NULL,NULL,'T003','Tiếng Anh');
INSERT INTO `users` VALUES (7,2,'0200000004',NULL,NULL,'hinh.bui56@fschool.edu.vn',_binary ' ','Bùi Xuân Hinh','$2a$10$k0sRoLWtIsxBWwGXeOUO2uHowBAx7Nwk/wnZuOTBNRR6TUiKCYBx2','2026-07-20 07:48:21.489167','2026-07-20 07:48:21.489167',NULL,NULL,NULL,'T004','Vật lý');
INSERT INTO `users` VALUES (8,2,'0200000005',NULL,NULL,'son.dang34@fschool.edu.vn',_binary ' ','Đặng Thái Sơn','$2a$10$Y/CyyJtJxILs3vHSO8Nn/.f8XjDs7M/BaKHTVb7cvzKuDRuONdMDa','2026-07-20 07:48:21.490700','2026-07-20 07:48:21.490700',NULL,NULL,NULL,'T005','Hóa học');
INSERT INTO `users` VALUES (9,2,'0200000006',NULL,NULL,'ha.ho12@fschool.edu.vn',_binary ' ','Hồ Ngọc Hà','$2a$10$ixP0uM/KfGY1SCpNNBi0aesOecs1b5GxuNsI4NyGEu8VpjOA7VlCe','2026-07-20 07:48:21.490700','2026-07-20 07:48:21.490700',NULL,NULL,NULL,'T006','Sinh học');
INSERT INTO `users` VALUES (10,2,'0200000007',NULL,NULL,'trung.do78@fschool.edu.vn',_binary ' ','Đỗ Đình Trung','$2a$10$HnUjWnej8qbrhyylntnp8usBajQtyodMAbmimOXcaUkL5vCcAk12.','2026-07-20 07:48:21.492228','2026-07-20 07:48:21.492228',NULL,NULL,NULL,'T007','Lịch sử');
INSERT INTO `users` VALUES (11,2,'0200000008',NULL,NULL,'ky.ly99@fschool.edu.vn',_binary ' ','Lý Nhã Kỳ','$2a$10$YdzQ2VQuyHStGSpt.hRtZObZQ4ZYX1CrB0Q750D0G6M8bTBS/TC7K','2026-07-20 07:48:21.493752','2026-07-20 07:48:21.493752',NULL,NULL,NULL,'T008','Địa lý');
INSERT INTO `users` VALUES (12,2,'0200000009',NULL,NULL,'son.trinh22@fschool.edu.vn',_binary ' ','Trịnh Công Sơn','$2a$10$C25PHUCGZuOY0edOibHTGOQzc9Ei2LCpmBwqgAq8hyZhEDVTWikJi','2026-07-20 07:48:21.493752','2026-07-20 07:48:21.493752',NULL,NULL,NULL,'T009','Tin học');
INSERT INTO `users` VALUES (13,2,'0200000010',NULL,NULL,'huy.ngo67@fschool.edu.vn',_binary ' ','Ngô Kiến Huy','$2a$10$UJigmPALU2mPTiAvCh4aRumHs7ojYnNV69/RI.8Z7xf6ufooaCYIu','2026-07-20 07:48:21.496292','2026-07-20 07:48:21.496292',NULL,NULL,NULL,'T010','GDCD');
INSERT INTO `users` VALUES (14,2,'0200000011',NULL,NULL,'huu.luong44@fschool.edu.vn',_binary ' ','Lương Bích Hữu','$2a$10$D6HKAhmXwh9oGqkx3XQsx.vf.4wGvE.RyCFDJj2bI.ZCMaE3npfSu','2026-07-20 07:48:21.497292','2026-07-20 07:48:21.497292',NULL,NULL,NULL,'T011','Thể dục');
INSERT INTO `users` VALUES (15,3,'0999999999',NULL,NULL,'anh.pham00@fschool.edu.vn',_binary ' ','Phạm Tuấn Anh','$2a$10$6fMjcEMRgh33l2SyZnf1a.wRd6vt1Bn/InZe0n.7Yi3.iz6hl8dza','2026-07-20 07:48:21.498291','2026-07-20 07:48:21.498291',NULL,NULL,NULL,NULL,NULL);
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

-- Dump completed on 2026-07-20 17:51:53


-- Mock data for Payment Flow
INSERT INTO ee_categories VALUES (1,'MONTHLY','Học phí tháng',5000000.00,'START_OF_MONTH','2026-07-20 00:00:00');
INSERT INTO ee_categories VALUES (2,'MONTHLY','Tiền ăn bán trú',1500000.00,'START_OF_MONTH','2026-07-20 00:00:00');
INSERT INTO ee_categories VALUES (3,'MONTHLY','Tiền xe đưa đón',1000000.00,'START_OF_MONTH','2026-07-20 00:00:00');

INSERT INTO 	uition_fees VALUES (1, 1, 'PAID', 'Học phí Tháng 08/2026', 7500000.00, '2026-08', '2026-08-01 00:00:00', '2026-08-05 08:30:00');
INSERT INTO 	uition_fees VALUES (2, 1, 'UNPAID', 'Học phí Tháng 09/2026', 7500000.00, '2026-09', '2026-09-01 00:00:00', '2026-09-01 00:00:00');

INSERT INTO ee_details VALUES (1, 1, 1, 5000000.00, '2026-08-05 00:00:00', 'Học phí tháng');
INSERT INTO ee_details VALUES (2, 2, 1, 1500000.00, '2026-08-05 00:00:00', 'Tiền ăn bán trú');
INSERT INTO ee_details VALUES (3, 3, 1, 1000000.00, '2026-08-05 00:00:00', 'Tiền xe đưa đón');

INSERT INTO ee_details VALUES (4, 1, 2, 5000000.00, '2026-09-05 00:00:00', 'Học phí tháng');
INSERT INTO ee_details VALUES (5, 2, 2, 1500000.00, '2026-09-05 00:00:00', 'Tiền ăn bán trú');
INSERT INTO ee_details VALUES (6, 3, 2, 1000000.00, '2026-09-05 00:00:00', 'Tiền xe đưa đón');

INSERT INTO ee_payments VALUES (1, 1, 7500000.00, '2026-08-05 08:30:00', 'VNPAY', 'SUCCESS', 'VNP123456789', 'TXN987654321');
