class Submission {
  final int submissionId;
  final int workId;
  final String taskTitle;
  final String taskDescription;
  final String submissionText;
  final DateTime submittedAt;
  final DateTime dueDate;
  final String taskStatus;

  Submission({
    required this.submissionId,
    required this.workId,
    required this.taskTitle,
    required this.taskDescription,
    required this.submissionText,
    required this.submittedAt,
    required this.dueDate,
    required this.taskStatus,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      submissionId: int.parse(json['submission_id'].toString()),
      workId: int.parse(json['work_id'].toString()),
      taskTitle: json['task_title'],
      taskDescription: json['task_description'],
      submissionText: json['submission_text'],
      submittedAt: DateTime.parse(json['submitted_at']),
      dueDate: DateTime.parse(json['due_date']),
      taskStatus: json['task_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission_id': submissionId,
      'work_id': workId,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'submission_text': submissionText,
      'submitted_at': submittedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'task_status': taskStatus,
    };
  }
}
