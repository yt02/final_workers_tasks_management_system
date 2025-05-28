<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

// Check if all required fields are provided
if (!isset($_POST['work_id']) || !isset($_POST['worker_id']) || !isset($_POST['submission_text'])) {
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$work_id = $_POST['work_id'];
$worker_id = $_POST['worker_id'];
$submission_text = $_POST['submission_text'];
$is_editing = isset($_POST['is_editing']) && $_POST['is_editing'] === 'true';

try {
    // Start transaction
    $conn->begin_transaction();

    if ($is_editing) {
        // Update existing submission
        $stmt = $conn->prepare("UPDATE tbl_submissions SET submission_text = ?, submitted_at = NOW() WHERE work_id = ? AND worker_id = ?");
        $stmt->bind_param("sii", $submission_text, $work_id, $worker_id);
        $stmt->execute();
    } else {
        // Insert new submission
        $stmt = $conn->prepare("INSERT INTO tbl_submissions (work_id, worker_id, submission_text, submitted_at) VALUES (?, ?, ?, NOW())");
        $stmt->bind_param("iis", $work_id, $worker_id, $submission_text);
        $stmt->execute();

        // Update work status to completed
        $stmt = $conn->prepare("UPDATE tbl_works SET status = 'completed' WHERE id = ? AND assigned_to = ?");
        $stmt->bind_param("ii", $work_id, $worker_id);
        $stmt->execute();
    }

    // Commit transaction
    $conn->commit();
    
    echo json_encode([
        'success' => true, 
        'message' => $is_editing ? 'Submission updated successfully' : 'Work submitted successfully'
    ]);
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(['error' => 'Failed to submit work: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?> 