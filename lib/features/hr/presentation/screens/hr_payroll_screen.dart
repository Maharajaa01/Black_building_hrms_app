import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class _PayrollRow {
  _PayrollRow({
    required this.name,
    required this.employee,
    required this.employeeName,
    required this.gross,
    required this.deduction,
    required this.netPay,
    required this.startDate,
    required this.endDate,
  });
  final String name;
  final String employee;
  final String employeeName;
  final double gross;
  final double deduction;
  final double netPay;
  final DateTime startDate;
  final DateTime endDate;

  factory _PayrollRow.fromJson(Map<String, dynamic> json) {
    return _PayrollRow(
      name: json['name']?.toString() ?? '',
      employee: json['employee']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      gross: ((json['gross_pay'] as num?) ?? 0).toDouble(),
      deduction: ((json['total_deduction'] as num?) ?? 0).toDouble(),
      netPay: ((json['net_pay'] as num?) ?? 0).toDouble(),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

final _hrPayrollProvider = FutureProvider.autoDispose<List<_PayrollRow>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);

  final res = await dio.get<Map<String, dynamic>>(
    ApiEndpoints.salarySlip,
    queryParameters: <String, dynamic>{
      'fields': jsonEncode(<String>[
        'name',
        'employee',
        'employee_name',
        'gross_pay',
        'total_deduction',
        'net_pay',
        'start_date',
        'end_date',
      ]),
      'filters': jsonEncode(<List<String>>[
        <String>['start_date', '>=', DateFormatter.toFrappeDate(monthStart)],
      ]),
      'order_by': 'employee_name asc',
      'limit_page_length': 500,
    },
  );

  final data = res.data?['data'];
  if (data is! List) return <_PayrollRow>[];
  return data
      .whereType<Map<String, dynamic>>()
      .map(_PayrollRow.fromJson)
      .toList();
});

class HrPayrollScreen extends ConsumerWidget {
  const HrPayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payroll = ref.watch(_hrPayrollProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payroll overview')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(_hrPayrollProvider),
        child: payroll.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(_hrPayrollProvider),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No payroll yet this month',
                    message: 'Slips will appear once payroll has been processed.',
                    icon: Icons.payments_outlined,
                  ),
                ],
              );
            }

            final totalGross = rows.fold<double>(0, (s, r) => s + r.gross);
            final totalDeduction = rows.fold<double>(0, (s, r) => s + r.deduction);
            final totalNet = rows.fold<double>(0, (s, r) => s + r.netPay);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: <Widget>[
                      StatCard(
                        label: 'Gross',
                        value: _currency.format(totalGross),
                        icon: Icons.trending_up,
                        iconColor: AppColors.success,
                      ),
                      StatCard(
                        label: 'Deductions',
                        value: _currency.format(totalDeduction),
                        icon: Icons.trending_down,
                        iconColor: AppColors.danger,
                      ),
                      StatCard(
                        label: 'Net pay',
                        value: _currency.format(totalNet),
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.gold,
                      ),
                      StatCard(
                        label: 'Slips',
                        value: rows.length.toString(),
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'By employee'),
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
                          ListTile(
                            title: Text(
                              rows[i].employeeName.isEmpty ? rows[i].employee : rows[i].employeeName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${DateFormatter.displayDate(rows[i].startDate)} → ${DateFormatter.displayDate(rows[i].endDate)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            trailing: Text(
                              _currency.format(rows[i].netPay),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          if (i != rows.length - 1) const Divider(height: 1, indent: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
