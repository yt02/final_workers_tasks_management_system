-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 19, 2025 at 11:11 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `workers_tasks_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `tbl_workers`
--

CREATE TABLE `tbl_workers` (
  `id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `address` text NOT NULL,
  `profile_image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('male','female','other','prefer_not_to_say') DEFAULT 'prefer_not_to_say',
  `nationality` varchar(50) DEFAULT 'Malaysian',
  `emergency_contact_name` varchar(100) DEFAULT NULL,
  `emergency_contact_phone` varchar(20) DEFAULT NULL,
  `emergency_contact_relationship` varchar(50) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `postal_code` varchar(10) DEFAULT NULL,
  `country` varchar(50) DEFAULT 'Malaysia',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_workers`
--

INSERT INTO `tbl_workers` (`id`, `full_name`, `email`, `password`, `phone`, `address`, `profile_image`, `created_at`, `date_of_birth`, `gender`, `nationality`, `emergency_contact_name`, `emergency_contact_phone`, `emergency_contact_relationship`, `city`, `state`, `postal_code`, `country`, `updated_at`) VALUES
(1, 'Siti', 'tbl1@gmail.com', '7c222fb2927d828af22f592134e8932480637c0d', '012437894846', 'uum123', 'uploads/profile_images/68369297b0388.jpg', '2025-05-28 02:07:06', '1998-06-18', 'female', 'Malaysian', 'Mr Ali', '846870164816', 'father', 'sintok', 'kedah', '06100', 'Malaysia', '2025-06-18 01:48:46'),
(2, 'Mouse', 'mouse@gmail.com', '7c222fb2927d828af22f592134e8932480637c0d', '1234567894543', 'uum', 'uploads/profile_images/68369297b0388.jpg', '2025-05-28 04:35:35', '2010-06-01', 'female', 'Malaysian', 'lee zi jia', '018764864849', 'father', 'sintok', 'kedah', '06100', 'Malaysia', '2025-06-19 08:36:24'),
(3, 'Jennie Kim', 'jennie@gmail.com', '7c222fb2927d828af22f592134e8932480637c0d', '01543786445', 'uum', 'uploads/profile_images/6836a3866c211.jpg', '2025-05-28 05:47:50', NULL, 'prefer_not_to_say', 'Malaysian', NULL, NULL, NULL, NULL, NULL, NULL, 'Malaysia', '2025-06-18 01:21:17'),
(4, 'Lisa', 'lisa@gmail.com', '7c222fb2927d828af22f592134e8932480637c0d', '012435797948', 'thailand', 'uploads/profile_images/6836a42903e1b.jpg', '2025-05-28 05:50:33', NULL, 'prefer_not_to_say', 'Malaysian', NULL, NULL, NULL, NULL, NULL, NULL, 'Malaysia', '2025-06-18 01:21:17');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_workers`
--
ALTER TABLE `tbl_workers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_date_of_birth` (`date_of_birth`),
  ADD KEY `idx_gender` (`gender`),
  ADD KEY `idx_nationality` (`nationality`),
  ADD KEY `idx_city` (`city`),
  ADD KEY `idx_state` (`state`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tbl_workers`
--
ALTER TABLE `tbl_workers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
