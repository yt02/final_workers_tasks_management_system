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
    // Get worker profile details including personal information
    $stmt = $conn->prepare("
        SELECT
            id, full_name, email, phone, address, profile_image, created_at,
            date_of_birth, gender, nationality,
            emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
            city, state, postal_code, country, updated_at
        FROM tbl_workers
        WHERE id = ?
    ");
    $stmt->bind_param("i", $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $worker = $result->fetch_assoc();

        // Format the response to ensure consistent data types
        $formatted_worker = [
            'id' => (int)$worker['id'],
            'full_name' => $worker['full_name'] ?? '',
            'email' => $worker['email'] ?? '',
            'phone' => $worker['phone'] ?? '',
            'address' => $worker['address'] ?? '',
            'profile_image' => $worker['profile_image'],
            'created_at' => $worker['created_at'],
            'date_of_birth' => $worker['date_of_birth'],
            'gender' => $worker['gender'],
            'nationality' => $worker['nationality'] ?? 'Malaysian',
            'emergency_contact_name' => $worker['emergency_contact_name'],
            'emergency_contact_phone' => $worker['emergency_contact_phone'],
            'emergency_contact_relationship' => $worker['emergency_contact_relationship'],
            'city' => $worker['city'],
            'state' => $worker['state'],
            'postal_code' => $worker['postal_code'],
            'country' => $worker['country'] ?? 'Malaysia',
            'updated_at' => $worker['updated_at']
        ];

        echo json_encode([
            'success' => true,
            'worker' => $formatted_worker
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
