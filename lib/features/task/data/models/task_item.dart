enum TaskStatus { open, working, pendingReview, completed, cancelled, overdue }
enum TaskPriority { low, medium, high, urgent }

class TaskItem {
  const TaskItem({
    required this.name,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.progress,
    required this.expectedStart,
    required this.expectedEnd,
    required this.assignedTo,
    required this.assignedBy,
    required this.project,
  });

  final String name;
  final String subject;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final double progress;
  final DateTime? expectedStart;
  final DateTime? expectedEnd;
  final String assignedTo;
  final String assignedBy;
  final String project;

  bool get isOverdue =>
      expectedEnd != null &&
      expectedEnd!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '(no subject)',
      description: _stripHtml(json['description']?.toString() ?? ''),
      status: _parseStatus(json['status']?.toString() ?? 'Open'),
      priority: _parsePriority(json['priority']?.toString() ?? 'Medium'),
      progress: ((json['progress'] as num?) ?? 0).toDouble(),
      expectedStart: DateTime.tryParse(json['exp_start_date']?.toString() ?? ''),
      expectedEnd: DateTime.tryParse(json['exp_end_date']?.toString() ?? ''),
      assignedTo: json['_assign']?.toString() ?? '',
      assignedBy: json['owner']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
    );
  }

  static TaskStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'working':
        return TaskStatus.working;
      case 'pending review':
        return TaskStatus.pendingReview;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'overdue':
        return TaskStatus.overdue;
      default:
        return TaskStatus.open;
    }
  }

  static TaskPriority _parsePriority(String s) {
    switch (s.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  static String _stripHtml(String s) {
    return s.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
