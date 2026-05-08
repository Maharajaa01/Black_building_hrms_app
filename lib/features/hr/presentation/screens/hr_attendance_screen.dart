import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';

class _AttendanceRow {
  _AttendanceRow({
    required this.employee,
    required this.employeeName,
    required this.status,
    required this.inTime,
    required this.outTime,
    required this.lateMinutes,
    required this.earlyExitMinutes,
  });

  final String employee;
  final String employeeName;
  final String status;
  final DateTime? inTime;
  final DateTime? outTime;
  final double lateMinutes;
  final double earlyExitMinutes;

  factory _AttendanceRow.fromJson(Map<String, dynamic> json) {
    return _AttendanceRow(
      employee: json['employee']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Open',
      inTime: DateTime.tryParse(json['in_time']?.toString() ?? ''),
      outTime: DateTime.tryParse(json['out_time']?.toString() ?? ''),
      lateMinutes: ((json['late_entry'] as num?) ?? 0).toDouble(),
      earlyExitMinutes: ((json['early_exit'] as num?) ?? 0).toDouble(),
    );
  }
}

final _selectedDateProvider = StateProvider.autoDispose<DateTime>((_) => DateTime.now());

final _hrAttendanceProvider =
    FutureProvider.autoDispose<List<_AttendanceRow>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final date = ref.watch(_selectedDateProvider);

  final res = await dio.get<Map<String, dynamic>>(
    ApiEndpoints.attendance,
    queryParameters: <String, dynamic>{
      'fields': jsonEncode(<String>[
        'employee',
        'employee_name',
        'status',
        'in_time',
        'out_time',
        'late_entry',
        'early_exit',
      ]),
      'filters': jsonEncode(<List<String>>[
        <String>['attendance_date', '=', DateFormatter.toFrappeDate(date)],
      ]),
      'order_by': 'employee_name asc',
      'limit_page_length': 200,
    },
  );

  final data = res.data?['data'];
  if (data is! List) return <_AttendanceRow>[];
  return data
      .whereType<Map<String, dynamic>>()
      .map(_AttendanceRow.fromJson)
      .toList();
});

class HrAttendanceScreen extends ConsumerWidget {
  const HrAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedDateProvider);
    final attendance = ref.watch(_hrAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_hrAttendanceProvider),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selected,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  ref.read(_selectedDateProvider.notifier).state = picked;
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormatter.displayDateLong(selected),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.expand_more, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () async => ref.invalidate(_hrAttendanceProvider),
              child: attendance.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(_hrAttendanceProvider),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        SizedBox(height: 80),
                        EmptyState(
                          title: 'No attendance for this day',
                          message: 'Try a different date or pull to refresh.',
                          icon: Icons.fact_check_outlined,
                        ),
                      ],
                    );
                  }

                  final late = rows.where((r) => r.lateMinutes > 0).toList();
                  final early = rows.where((r) => r.earlyExitMinutes > 0).toList();

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                    children: <Widget>[
                      const SectionHeader(title: 'Today\'s register'),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: <Widget>[
                              for (int i = 0; i < rows.length; i++) ...<Widget>[
                                _RowTile(row: rows[i]),
                                if (i != rows.length - 1) const Divider(height: 1, indent: 60),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (late.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Late entries'),
                        const SizedBox(height: 8),
                        _MiniList(rows: late, mode: _MiniMode.late),
                      ],
                      if (early.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Early exits'),
                        const SizedBox(height: 8),
                        _MiniList(rows: early, mode: _MiniMode.early),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MiniMode { late, early }

class _MiniList extends StatelessWidget {
  const _MiniList({required this.rows, required this.mode});
  final List<_AttendanceRow> rows;
  final _MiniMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              ListTile(
                title: Text(
                  rows[i].employeeName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  mode == _MiniMode.late
                      ? '${rows[i].lateMinutes.toStringAsFixed(0)}m late'
                      : '${rows[i].earlyExitMinutes.toStringAsFixed(0)}m early',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (i != rows.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});
  final _AttendanceRow row;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          row.employeeName.isEmpty ? '?' : row.employeeName.characters.first.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldDark),
        ),
      ),
      title: Text(
        row.employeeName.isEmpty ? row.employee : row.employeeName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${row.inTime == null ? '—' : DateFormatter.displayTime(row.inTime!)} → '
        '${row.outTime == null ? '—' : DateFormatter.displayTime(row.outTime!)}',
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      trailing: StatusBadge.forStatus(row.status),
    );
  }
}
