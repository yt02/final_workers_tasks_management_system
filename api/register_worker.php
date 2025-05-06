<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
    exit();
}

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

// Debug received data
error_log('Received registration data: ' . print_r($data, true));

// Validate required fields
$required_fields = ['full_name', 'email', 'password', 'phone', 'address'];
foreach ($required_fields as $field) {
    if (empty($data[$field])) {
        echo json_encode(['success' => false, 'message' => ucfirst($field) . ' is required']);
        exit();
    }
}

// Validate email format
if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Invalid email format']);
    exit();
}

// Validate password length
if (strlen($data['password']) < 6) {
    echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters']);
    exit();
}

try {
    // Check if email already exists
    $stmt = $pdo->prepare("SELECT id FROM workers WHERE email = ?");
    $stmt->execute([$data['email']]);
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'Email already registered']);
        exit();
    }

    // Hash password using SHA1
    $hashed_password = sha1($data['password']);

    // Insert new worker
    $stmt = $pdo->prepare("INSERT INTO workers (full_name, email, password, phone, address) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([
        $data['full_name'],
        $data['email'],
        $hashed_password,
        $data['phone'],
        $data['address']
    ]);

    echo json_encode(['success' => true, 'message' => 'Registration successful']);
} catch(PDOException $e) {
    error_log('Database error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()]);
}
?> 