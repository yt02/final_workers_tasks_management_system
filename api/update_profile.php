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

// Personal Information Fields
$date_of_birth = (isset($_POST['date_of_birth']) && !empty($_POST['date_of_birth'])) ? $_POST['date_of_birth'] : null;
$gender = isset($_POST['gender']) ? $_POST['gender'] : 'prefer_not_to_say';
$nationality = isset($_POST['nationality']) ? $_POST['nationality'] : 'Malaysian';

// Emergency Contact Fields
$emergency_contact_name = isset($_POST['emergency_contact_name']) ? $_POST['emergency_contact_name'] : null;
$emergency_contact_phone = isset($_POST['emergency_contact_phone']) ? $_POST['emergency_contact_phone'] : null;
$emergency_contact_relationship = isset($_POST['emergency_contact_relationship']) ? $_POST['emergency_contact_relationship'] : null;

// Address Fields
$city = isset($_POST['city']) ? $_POST['city'] : null;
$state = isset($_POST['state']) ? $_POST['state'] : null;
$postal_code = isset($_POST['postal_code']) ? $_POST['postal_code'] : null;
$country = isset($_POST['country']) ? $_POST['country'] : 'Malaysia';

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
    
    // Update worker profile with personal information
    $stmt = $conn->prepare("
        UPDATE tbl_workers SET
            full_name = ?, email = ?, phone = ?, address = ?,
            date_of_birth = ?, gender = ?, nationality = ?,
            emergency_contact_name = ?, emergency_contact_phone = ?, emergency_contact_relationship = ?,
            city = ?, state = ?, postal_code = ?, country = ?
        WHERE id = ?
    ");
    $stmt->bind_param(
        "ssssssssssssssi",
        $full_name, $email, $phone, $address,
        $date_of_birth, $gender, $nationality,
        $emergency_contact_name, $emergency_contact_phone, $emergency_contact_relationship,
        $city, $state, $postal_code, $country,
        $worker_id
    );
    
    if ($stmt->execute()) {
        // Always return success if the query executed without errors
        // Even if no rows were affected (same values), it's still a successful update

        // Get updated profile data including personal information
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
        $worker = $result->fetch_assoc();

        if ($worker) {
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
                'message' => 'Profile updated successfully',
                'worker' => $formatted_worker
            ]);
        } else {
            echo json_encode(['error' => 'Worker not found after update']);
        }
    } else {
        echo json_encode(['error' => 'Failed to execute update query: ' . $stmt->error]);
    }
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to update profile: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
