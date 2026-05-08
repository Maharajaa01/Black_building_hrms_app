enum LeaveStatus { open, approved, rejected, cancelled }

class LeaveApplication {
  const LeaveApplication({
    required this.name,
    required this.employee,
    required this.employeeName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalLeaveDays,
    required this.reason,
    required this.status,
    required this.postedOn,
    required this.approver,
  });

  final String name;
  final String employee;
  final String employeeName;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final double totalLeaveDays;
  final String reason;
  final LeaveStatus status;
  final DateTime? postedOn;
  final String approver;

  bool get isPending => status == LeaveStatus.open;

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      name: json['name']?.toString() ?? '',
      employee: json['employee']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      leaveType: json['leave_type']?.toString() ?? '',
      fromDate: DateTime.parse(json['from_date'].toString()),
      toDate: DateTime.parse(json['to_date'].toString()),
      totalLeaveDays: ((json['total_leave_days'] as num?) ?? 0).toDouble(),
      reason: json['description']?.toString() ?? json['reason']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString() ?? 'Open'),
      postedOn: DateTime.tryParse(json['posting_date']?.toString() ?? ''),
      approver: json['leave_approver']?.toString() ?? '',
    );
  }

  static LeaveStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.open;
    }
  }
}

class LeaveType {
  const LeaveType({required this.name, required this.maxDays});
  final String name;
  final double maxDays;

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      name: json['name']?.toString() ?? '',
      maxDays: ((json['max_leaves_allowed'] as num?) ?? 0).toDouble(),
    );
  }
}

class LeaveBalance {
  const LeaveBalance({required this.leaveType, required this.balance});
  final String leaveType;
  final double balance;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveType: json['leave_type']?.toString() ?? '',
      balance: ((json['balance'] as num?) ?? 0).toDouble(),
    );
  }
}
