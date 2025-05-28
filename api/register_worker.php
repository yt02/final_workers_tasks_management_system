<?php
// Prevent any HTML output
error_reporting(0);
ini_set('display_errors', 0);

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
$data = $_POST;

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
    $stmt = $conn->prepare("SELECT id FROM tbl_workers WHERE email = ?");
    if (!$stmt) {
        throw new Exception("Failed to prepare email check statement: " . $conn->error);
    }
    
    $stmt->bind_param("s", $data['email']);
    if (!$stmt->execute()) {
        throw new Exception("Failed to execute email check: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        echo json_encode(['success' => false, 'message' => 'Email already registered']);
        exit();
    }
    $stmt->close();

    // Handle image upload
    $profile_image_path = null;
    if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] === UPLOAD_ERR_OK) {
        $upload_dir = '../uploads/profile_images/';
        
        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        // Generate unique filename
        $file_extension = pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION);
        $filename = uniqid() . '.' . $file_extension;
        $target_path = $upload_dir . $filename;

        // Debug image upload
        error_log('Attempting to upload image to: ' . $target_path);
        error_log('Upload details: ' . print_r($_FILES['profile_image'], true));

        // Move uploaded file
        if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $target_path)) {
            $profile_image_path = 'uploads/profile_images/' . $filename;
            error_log('Image uploaded successfully. Path: ' . $profile_image_path);
            
            // Verify file exists after upload
            if (file_exists($target_path)) {
                error_log('File exists after upload. Size: ' . filesize($target_path));
                // Set proper permissions
                chmod($target_path, 0644);
            } else {
                error_log('File does not exist after upload!');
                $profile_image_path = null;
            }
        } else {
            error_log('Failed to move uploaded file. PHP Error: ' . error_get_last()['message']);
            $profile_image_path = null;
        }
    } else {
        error_log('No image uploaded or upload error occurred');
        $profile_image_path = null;
    }

    // Hash password using SHA1
    $hashed_password = sha1($data['password']);

    // Insert new worker
    $stmt = $conn->prepare("INSERT INTO tbl_workers (full_name, email, password, phone, address, profile_image) VALUES (?, ?, ?, ?, ?, ?)");
    if (!$stmt) {
        throw new Exception("Failed to prepare insert statement: " . $conn->error);
    }
    
    $stmt->bind_param("ssssss", 
        $data['full_name'],
        $data['email'],
        $hashed_password,
        $data['phone'],
        $data['address'],
        $profile_image_path
    );
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to insert worker: " . $stmt->error);
    }

    // Get the inserted worker's ID
    $worker_id = $conn->insert_id;

    echo json_encode([
        'success' => true, 
        'message' => 'Registration successful',
        'worker' => [
            'id' => $worker_id,
            'full_name' => $data['full_name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
            'address' => $data['address'],
            'profile_image' => $profile_image_path
        ]
    ]);
} catch (Exception $e) {
    error_log('Error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()]);
} finally {
    if (isset($stmt)) {
        $stmt->close();
    }
    if (isset($conn)) {
        $conn->close();
    }
}
?> 