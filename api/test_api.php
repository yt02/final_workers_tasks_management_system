<?php
require_once 'db_connection.php';

echo "Testing Database Connection...\n";
try {
    $stmt = $pdo->query("SELECT 1");
    echo "✓ Database connection successful\n";
} catch(PDOException $e) {
    echo "✗ Database connection failed: " . $e->getMessage() . "\n";
    exit();
}

echo "\nTesting Workers Table...\n";
try {
    $stmt = $pdo->query("SELECT COUNT(*) FROM workers");
    echo "✓ Workers table exists\n";
} catch(PDOException $e) {
    echo "✗ Workers table not found. Please run create_workers_table.sql first\n";
    exit();
}

echo "\nSample API Test Data:\n";
echo "1. Registration Test Data:\n";
echo json_encode([
    'full_name' => 'John Doe',
    'email' => 'john@example.com',
    'password' => 'password123',
    'phone' => '0123456789',
    'address' => '123 Test Street'
], JSON_PRETTY_PRINT);

echo "\n2. Login Test Data:\n";
echo json_encode([
    'email' => 'john@example.com',
    'password' => 'password123'
], JSON_PRETTY_PRINT);

echo "\nAPI Endpoints:\n";
echo "1. Registration: http://localhost/workers_tasks_management_system/api/register_worker.php\n";
echo "2. Login: http://localhost/workers_tasks_management_system/api/login_worker.php\n";
?> 