import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/models/salary_slip.dart';
import '../../data/salary_repository.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

class SalaryDetailScreen extends ConsumerWidget {
  const SalaryDetailScreen({required this.slipId, super.key});
  final String slipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slipAsync = ref.watch(salarySlipDetailProvider(slipId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Slip'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: slipAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(salarySlipDetailProvider(slipId)),
        ),
        data: (slip) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            _Header(slip: slip),
            const SizedBox(height: 16),
            _Section(
              title: 'Earnings',
              total: slip.gross,
              items: slip.earnings,
              positive: true,
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Deductions',
              total: slip.totalDeduction,
              items: slip.deductions,
              positive: false,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  const Text(
                    'Net pay',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    _currency.format(slip.netPay),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final base = Env.apiBaseUrl;
    final uri = Uri.parse(
      '$base${ApiEndpoints.printFormat}'
      '?doctype=Salary+Slip&name=${Uri.encodeQueryComponent(slipId)}'
      '&format=Salary+Slip+Standard&no_letterhead=0',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open PDF on this device.')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.slip});
  final SalarySlip slip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            slip.employeeName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            'Slip ${slip.name}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _Metric(
                  label: 'Period',
                  value:
                      '${DateFormatter.displayDate(slip.startDate)} → ${DateFormatter.displayDate(slip.endDate)}',
                ),
              ),
              Expanded(
                child: _Metric(label: 'Frequency', value: slip.payrollFrequency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.total,
    required this.items,
    required this.positive,
  });
  final String title;
  final double total;
  final List<SalaryComponent> items;
  final bool positive;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = widget.positive ? AppColors.success : AppColors.danger;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.positive ? '+' : '−'} ${_currency.format(widget.total)}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (_expanded && widget.items.isNotEmpty) const Divider(height: 1),
          if (_expanded)
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      _currency.format(item.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
