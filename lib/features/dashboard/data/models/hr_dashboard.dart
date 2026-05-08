class HrDashboard {
  const HrDashboard({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.absentToday,
    required this.onLeaveToday,
    required this.pendingLeaveApprovals,
    required this.openTasks,
    required this.payrollTotal,
    required this.recentActivity,
  });

  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int absentToday;
  final int onLeaveToday;
  final int pendingLeaveApprovals;
  final int openTasks;
  final double payrollTotal;
  final List<HrActivity> recentActivity;

  double get attendanceRate =>
      totalEmployees == 0 ? 0 : (presentToday + lateToday) / totalEmployees;

  factory HrDashboard.fromJson(Map<String, dynamic> json) {
    final activity = json['recent_activity'];
    return HrDashboard(
      totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
      presentToday: (json['present_today'] as num?)?.toInt() ?? 0,
      lateToday: (json['late_today'] as num?)?.toInt() ?? 0,
      absentToday: (json['absent_today'] as num?)?.toInt() ?? 0,
      onLeaveToday: (json['on_leave_today'] as num?)?.toInt() ?? 0,
      pendingLeaveApprovals: (json['pending_leave_approvals'] as num?)?.toInt() ?? 0,
      openTasks: (json['open_tasks'] as num?)?.toInt() ?? 0,
      payrollTotal: ((json['payroll_total'] as num?) ?? 0).toDouble(),
      recentActivity: activity is List
          ? activity
              .whereType<Map<String, dynamic>>()
              .map(HrActivity.fromJson)
              .toList()
          : <HrActivity>[],
    );
  }
}

class HrActivity {
  const HrActivity({
    required this.employee,
    required this.employeeName,
    required this.kind,
    required this.message,
    required this.time,
  });

  final String employee;
  final String employeeName;
  final String kind; // checkin, checkout, leave_applied, task_done
  final String message;
  final DateTime time;

  factory HrActivity.fromJson(Map<String, dynamic> json) {
    return HrActivity(
      employee: json['employee']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
