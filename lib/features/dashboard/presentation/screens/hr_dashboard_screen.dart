import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/hr_dashboard.dart';
import '../widgets/greeting_header.dart';

class HrDashboardScreen extends ConsumerWidget {
  const HrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hrDashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async => ref.invalidate(hrDashboardProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              const GreetingHeader(),
              const SizedBox(height: 8),
              state.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: LoadingView(message: 'Loading HR insights…'),
                ),
                error: (e, _) => SizedBox(
                  height: 220,
                  child: ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(hrDashboardProvider),
                  ),
                ),
                data: (d) => _Body(data: d),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final HrDashboard data;

  @override
  Widget build(BuildContext context) {
    final pieSections = <PieChartSectionData>[
      _section(data.presentToday.toDouble(), AppColors.success, 'P'),
      _section(data.lateToday.toDouble(), AppColors.warning, 'L'),
      _section(data.onLeaveToday.toDouble(), AppColors.info, 'Lv'),
      _section(data.absentToday.toDouble(), AppColors.danger, 'A'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PieChart(
                        PieChartData(
                          sections: pieSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          startDegreeOffset: -90,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${(data.attendanceRate * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            'Attendance',
                            style: TextStyle(color: Colors.white60, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Today',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.displayDateLong(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(label: 'Present', value: data.presentToday, color: AppColors.success),
                      _LegendRow(label: 'Late', value: data.lateToday, color: AppColors.warning),
                      _LegendRow(label: 'On leave', value: data.onLeaveToday, color: AppColors.info),
                      _LegendRow(label: 'Absent', value: data.absentToday, color: AppColors.danger),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'At a glance'),
        const SizedBox(height: 8),
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
                label: 'Total employees',
                value: data.totalEmployees.toString(),
                icon: Icons.groups_outlined,
                iconColor: AppColors.info,
              ),
              StatCard(
                label: 'Pending leave',
                value: data.pendingLeaveApprovals.toString(),
                subtitle: 'Awaiting approval',
                icon: Icons.approval_outlined,
                iconColor: AppColors.warning,
              ),
              StatCard(
                label: 'Open tasks',
                value: data.openTasks.toString(),
                icon: Icons.assignment_outlined,
                iconColor: AppColors.gold,
              ),
              StatCard(
                label: 'Payroll (₹)',
                value: _short(data.payrollTotal),
                subtitle: 'Current month',
                icon: Icons.payments_outlined,
                iconColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: 8),
        if (data.recentActivity.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No recent activity to show.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < data.recentActivity.length; i++) ...<Widget>[
                    _ActivityRow(activity: data.recentActivity[i]),
                    if (i != data.recentActivity.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _short(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  PieChartSectionData _section(double v, Color c, String label) {
    return PieChartSectionData(
      value: v < 0.5 ? 0.5 : v,
      color: c,
      radius: 18,
      showTitle: false,
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final HrActivity activity;

  @override
  Widget build(BuildContext context) {
    final icon = switch (activity.kind) {
      'checkin' => Icons.login,
      'checkout' => Icons.logout,
      'leave_applied' => Icons.event_busy_outlined,
      'task_done' => Icons.check_circle_outline,
      _ => Icons.notifications_outlined,
    };

    final color = switch (activity.kind) {
      'checkin' => AppColors.success,
      'checkout' => AppColors.info,
      'leave_applied' => AppColors.warning,
      'task_done' => AppColors.gold,
      _ => AppColors.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  activity.message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormatter.relative(activity.time),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
