<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

// Check if worker_id is provided
if (!isset($_POST['worker_id'])) {
    echo json_encode(['error' => 'Worker ID is required']);
    exit;
}

$worker_id = $_POST['worker_id'];

try {
    // Get worker profile details
    $stmt = $conn->prepare("SELECT id, full_name, email, phone, address, profile_image, created_at FROM tbl_workers WHERE id = ?");
    $stmt->bind_param("i", $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $worker = $result->fetch_assoc();
        echo json_encode([
            'success' => true,
            'worker' => $worker
        ]);
    } else {
        echo json_encode(['error' => 'Worker not found']);
    }
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to fetch profile: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
