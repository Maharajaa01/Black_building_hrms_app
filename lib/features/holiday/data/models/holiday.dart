class Holiday {
  const Holiday({
    required this.date,
    required this.description,
    required this.weeklyOff,
  });

  final DateTime date;
  final String description;
  final bool weeklyOff;

  bool get isUpcoming => !date.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['holiday_date'].toString()),
      description: json['description']?.toString() ?? 'Holiday',
      weeklyOff: (json['weekly_off'] as int? ?? 0) == 1,
    );
  }
}
