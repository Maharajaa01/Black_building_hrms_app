class SalarySlip {
  const SalarySlip({
    required this.name,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.gross,
    required this.totalDeduction,
    required this.netPay,
    required this.payrollFrequency,
    required this.status,
    required this.earnings,
    required this.deductions,
  });

  final String name;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  final double gross;
  final double totalDeduction;
  final double netPay;
  final String payrollFrequency;
  final String status;
  final List<SalaryComponent> earnings;
  final List<SalaryComponent> deductions;

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      name: json['name']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      gross: ((json['gross_pay'] as num?) ?? 0).toDouble(),
      totalDeduction: ((json['total_deduction'] as num?) ?? 0).toDouble(),
      netPay: ((json['net_pay'] as num?) ?? 0).toDouble(),
      payrollFrequency: json['payroll_frequency']?.toString() ?? 'Monthly',
      status: json['status']?.toString() ?? '',
      earnings: _parseComponents(json['earnings']),
      deductions: _parseComponents(json['deductions']),
    );
  }

  static List<SalaryComponent> _parseComponents(dynamic raw) {
    if (raw is! List) return <SalaryComponent>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SalaryComponent.fromJson)
        .toList();
  }
}

class SalaryComponent {
  const SalaryComponent({required this.name, required this.amount});
  final String name;
  final double amount;

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    return SalaryComponent(
      name: json['salary_component']?.toString() ??
          json['component']?.toString() ??
          '—',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
    );
  }
}
