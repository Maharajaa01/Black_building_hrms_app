/// Aggregated payload returned by the custom mobile API
/// `bb_acadamy_admin.api.mobile.employee_dashboard`.
class EmployeeDashboard {
  const EmployeeDashboard({
    required this.attendanceStatus,
    required this.checkInTime,
    required this.checkOutTime,
    required this.lateMinutes,
    required this.earlyExitMinutes,
    required this.workedMinutes,
    required this.pendingTasks,
    required this.openLeaves,
    required this.leaveBalance,
    required this.upcomingHoliday,
  });

  final String attendanceStatus; // not_checked_in | working | completed | on_leave | holiday
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double lateMinutes;
  final double earlyExitMinutes;
  final int workedMinutes;
  final int pendingTasks;
  final int openLeaves;
  final double leaveBalance;
  final UpcomingHoliday? upcomingHoliday;

  Duration get workedDuration => Duration(minutes: workedMinutes);
  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;

  factory EmployeeDashboard.fromJson(Map<String, dynamic> json) {
    return EmployeeDashboard(
      attendanceStatus: json['attendance_status']?.toString() ?? 'not_checked_in',
      checkInTime: _parseDate(json['check_in_time']),
      checkOutTime: _parseDate(json['check_out_time']),
      lateMinutes: _toDouble(json['late_minutes']),
      earlyExitMinutes: _toDouble(json['early_exit_minutes']),
      workedMinutes: (json['worked_minutes'] as num?)?.toInt() ?? 0,
      pendingTasks: (json['pending_tasks'] as num?)?.toInt() ?? 0,
      openLeaves: (json['open_leaves'] as num?)?.toInt() ?? 0,
      leaveBalance: _toDouble(json['leave_balance']),
      upcomingHoliday: json['upcoming_holiday'] is Map<String, dynamic>
          ? UpcomingHoliday.fromJson(json['upcoming_holiday'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UpcomingHoliday {
  const UpcomingHoliday({required this.date, required this.description});
  final DateTime date;
  final String description;

  factory UpcomingHoliday.fromJson(Map<String, dynamic> json) {
    return UpcomingHoliday(
      date: DateTime.parse(json['holiday_date'].toString()),
      description: json['description']?.toString() ?? 'Holiday',
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
