enum AttendanceMark { present, late, absent, halfDay, onLeave, holiday, weeklyOff, none }

class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.mark,
    required this.checkIn,
    required this.checkOut,
    required this.lateMinutes,
    required this.earlyExitMinutes,
    required this.workingHours,
    required this.note,
  });

  final DateTime date;
  final AttendanceMark mark;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double lateMinutes;
  final double earlyExitMinutes;
  final double workingHours;
  final String note;

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    return AttendanceDay(
      date: DateTime.parse(json['date'].toString()),
      mark: _parseMark(json['mark']?.toString() ?? json['status']?.toString() ?? ''),
      checkIn: _parseDateTime(json['check_in']),
      checkOut: _parseDateTime(json['check_out']),
      lateMinutes: ((json['late_minutes'] as num?) ?? 0).toDouble(),
      earlyExitMinutes: ((json['early_exit_minutes'] as num?) ?? 0).toDouble(),
      workingHours: ((json['working_hours'] as num?) ?? 0).toDouble(),
      note: json['note']?.toString() ?? '',
    );
  }

  static AttendanceMark _parseMark(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return AttendanceMark.present;
      case 'late':
        return AttendanceMark.late;
      case 'absent':
        return AttendanceMark.absent;
      case 'half day':
      case 'half_day':
        return AttendanceMark.halfDay;
      case 'on leave':
      case 'on_leave':
        return AttendanceMark.onLeave;
      case 'holiday':
        return AttendanceMark.holiday;
      case 'weekly off':
      case 'weekly_off':
        return AttendanceMark.weeklyOff;
      default:
        return AttendanceMark.none;
    }
  }
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalLeaves,
    required this.totalHolidays,
    required this.totalEarlyExits,
    required this.workingHours,
  });

  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalLeaves;
  final int totalHolidays;
  final int totalEarlyExits;
  final double workingHours;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalPresent: (json['total_present'] as num?)?.toInt() ?? 0,
      totalLate: (json['total_late'] as num?)?.toInt() ?? 0,
      totalAbsent: (json['total_absent'] as num?)?.toInt() ?? 0,
      totalLeaves: (json['total_leaves'] as num?)?.toInt() ?? 0,
      totalHolidays: (json['total_holidays'] as num?)?.toInt() ?? 0,
      totalEarlyExits: (json['total_early_exits'] as num?)?.toInt() ?? 0,
      workingHours: ((json['working_hours'] as num?) ?? 0).toDouble(),
    );
  }
}

class MonthlyAttendance {
  const MonthlyAttendance({required this.summary, required this.days});
  final AttendanceSummary summary;
  final List<AttendanceDay> days;

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'];
    return MonthlyAttendance(
      summary: AttendanceSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      days: daysJson is List
          ? daysJson
              .whereType<Map<String, dynamic>>()
              .map(AttendanceDay.fromJson)
              .toList()
          : <AttendanceDay>[],
    );
  }
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
