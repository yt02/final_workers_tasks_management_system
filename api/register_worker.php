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
    $stmt = $pdo->prepare("SELECT id FROM workers WHERE email = ?");
    $stmt->execute([$data['email']]);
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'Email already registered']);
        exit();
    }

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

    try {
        // Insert new worker with NULL for profile_image if no image was uploaded
        $stmt = $pdo->prepare("INSERT INTO workers (full_name, email, password, phone, address, profile_image) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['full_name'],
            $data['email'],
            $hashed_password,
            $data['phone'],
            $data['address'],
            $profile_image_path
        ]);

        echo json_encode(['success' => true, 'message' => 'Registration successful']);
    } catch(PDOException $e) {
        error_log('Database error: ' . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()]);
    }
} catch(PDOException $e) {
    error_log('Database error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()]);
}
?> 