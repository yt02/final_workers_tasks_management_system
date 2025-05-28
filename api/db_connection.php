<?php
// Prevent any HTML output
error_reporting(0);
ini_set('display_errors', 0);

$host = 'localhost';
$username = 'root';
$password = '';
$database = 'workers_tasks_db';

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]));
}

// Set charset to ensure proper encoding
$conn->set_charset("utf8mb4");
?> 