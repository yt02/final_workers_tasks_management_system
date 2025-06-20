class Work {
  final int id;
  final String title;
  final String description;
  final DateTime dateAssigned;
  final DateTime dueDate;
  final String status;
  final int? submissionId;
  final String? submissionText;
  final DateTime? submittedAt;

  Work({
    required this.id,
    required this.title,
    required this.description,
    required this.dateAssigned,
    required this.dueDate,
    required this.status,
    this.submissionId,
    this.submissionText,
    this.submittedAt,
  });

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      id: int.parse(json['id'].toString()),
      title: json['title'],
      description: json['description'],
      dateAssigned: DateTime.parse(json['date_assigned']),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      submissionId: json['submission_id'] != null
          ? int.parse(json['submission_id'].toString())
          : null,
      submissionText: json['submission_text'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_assigned': dateAssigned.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'submission_id': submissionId,
      'submission_text': submissionText,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}