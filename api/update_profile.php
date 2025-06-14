<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

// Check if all required fields are provided
if (!isset($_POST['worker_id']) || !isset($_POST['full_name']) || !isset($_POST['email']) || !isset($_POST['phone'])) {
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$worker_id = $_POST['worker_id'];
$full_name = $_POST['full_name'];
$email = $_POST['email'];
$phone = $_POST['phone'];
$address = isset($_POST['address']) ? $_POST['address'] : '';

try {
    // Check if email is already taken by another user
    $stmt = $conn->prepare("SELECT id FROM tbl_workers WHERE email = ? AND id != ?");
    $stmt->bind_param("si", $email, $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode(['error' => 'Email is already taken by another user']);
        exit;
    }
    
    // Update worker profile
    $stmt = $conn->prepare("UPDATE tbl_workers SET full_name = ?, email = ?, phone = ?, address = ? WHERE id = ?");
    $stmt->bind_param("ssssi", $full_name, $email, $phone, $address, $worker_id);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            // Get updated profile data
            $stmt = $conn->prepare("SELECT id, full_name, email, phone, address, profile_image, created_at FROM tbl_workers WHERE id = ?");
            $stmt->bind_param("i", $worker_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $worker = $result->fetch_assoc();
            
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'worker' => $worker
            ]);
        } else {
            echo json_encode(['error' => 'No changes made to profile']);
        }
    } else {
        echo json_encode(['error' => 'Failed to update profile']);
    }
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to update profile: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
