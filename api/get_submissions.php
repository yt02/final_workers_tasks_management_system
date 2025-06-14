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
    // Get submissions with task details
    $stmt = $conn->prepare("
        SELECT 
            s.id as submission_id,
            s.work_id,
            s.submission_text,
            s.submitted_at,
            w.title as task_title,
            w.description as task_description,
            w.due_date,
            w.status as task_status
        FROM tbl_submissions s
        JOIN tbl_works w ON s.work_id = w.id
        WHERE s.worker_id = ?
        ORDER BY s.submitted_at DESC
    ");
    
    $stmt->bind_param("i", $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $submissions = [];
    while ($row = $result->fetch_assoc()) {
        $submissions[] = [
            'submission_id' => $row['submission_id'],
            'work_id' => $row['work_id'],
            'task_title' => $row['task_title'],
            'task_description' => $row['task_description'],
            'submission_text' => $row['submission_text'],
            'submitted_at' => $row['submitted_at'],
            'due_date' => $row['due_date'],
            'task_status' => $row['task_status']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'submissions' => $submissions
    ]);
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Failed to fetch submissions: ' . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
