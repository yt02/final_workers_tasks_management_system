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
error_log('Received login data: ' . print_r($data, true));

// Validate required fields
if (empty($data['email']) || empty($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Email and password are required']);
    exit();
}

try {
    // Hash password using SHA1
    $hashed_password = sha1($data['password']);

    // Check credentials
    $stmt = $pdo->prepare("SELECT id, full_name, email, phone, address FROM workers WHERE email = ? AND password = ?");
    $stmt->execute([$data['email'], $hashed_password]);
    
    if ($stmt->rowCount() > 0) {
        $worker = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'worker' => $worker
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
    }
} catch(PDOException $e) {
    error_log('Database error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Login failed: ' . $e->getMessage()]);
}
?> 