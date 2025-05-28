<?php
// Prevent any HTML output
error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');
require_once 'db_connection.php';

// Check if worker_id is provided
if (!isset($_POST['worker_id'])) {
    echo json_encode(['error' => 'Worker ID is required']);
    exit;
}

$worker_id = $_POST['worker_id'];

try {
    // First verify if the worker exists
    $check_stmt = $conn->prepare("SELECT id FROM tbl_workers WHERE id = ?");
    if (!$check_stmt) {
        throw new Exception("Failed to prepare worker check statement: " . $conn->error);
    }
    
    $check_stmt->bind_param("i", $worker_id);
    if (!$check_stmt->execute()) {
        throw new Exception("Failed to execute worker check: " . $check_stmt->error);
    }
    
    $check_result = $check_stmt->get_result();
    if ($check_result->num_rows === 0) {
        echo json_encode(['error' => 'Worker not found']);
        exit;
    }
    $check_stmt->close();

    // Get works for the worker
    $stmt = $conn->prepare("
        SELECT w.*, s.submission_text, s.submitted_at 
        FROM tbl_works w 
        LEFT JOIN tbl_submissions s ON w.id = s.work_id AND s.worker_id = ?
        WHERE w.assigned_to = ? 
        ORDER BY w.due_date ASC
    ");
    if (!$stmt) {
        throw new Exception("Failed to prepare statement: " . $conn->error);
    }
    
    $stmt->bind_param("ii", $worker_id, $worker_id);
    if (!$stmt->execute()) {
        throw new Exception("Failed to execute statement: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    if (!$result) {
        throw new Exception("Failed to get result: " . $stmt->error);
    }
    
    $works = [];
    while ($row = $result->fetch_assoc()) {
        $works[] = [
            'id' => $row['id'],
            'title' => $row['title'],
            'description' => $row['description'],
            'date_assigned' => $row['date_assigned'],
            'due_date' => $row['due_date'],
            'status' => $row['status'],
            'submission_text' => $row['submission_text'],
            'submitted_at' => $row['submitted_at']
        ];
    }
    
    // Return success even if no works found
    echo json_encode([
        'success' => true, 
        'works' => $works,
        'message' => empty($works) ? 'No tasks assigned yet' : null
    ]);
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to fetch works: ' . $e->getMessage()]);
} finally {
    if (isset($stmt)) {
        $stmt->close();
    }
    if (isset($conn)) {
        $conn->close();
    }
}
?> 