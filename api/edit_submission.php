<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

// Check if all required fields are provided
if (!isset($_POST['submission_id']) || !isset($_POST['updated_text'])) {
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$submission_id = $_POST['submission_id'];
$updated_text = $_POST['updated_text'];

try {
    // Update the submission text
    $stmt = $conn->prepare("UPDATE tbl_submissions SET submission_text = ?, submitted_at = NOW() WHERE id = ?");
    $stmt->bind_param("si", $updated_text, $submission_id);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Submission updated successfully'
            ]);
        } else {
            echo json_encode(['error' => 'Submission not found or no changes made']);
        }
    } else {
        echo json_encode(['error' => 'Failed to update submission']);
    }
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to update submission: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
