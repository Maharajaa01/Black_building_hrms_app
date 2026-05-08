import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/employee_dashboard.dart';
import '../widgets/check_in_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_actions.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(employeeDashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async => ref.invalidate(employeeDashboardProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              const GreetingHeader(),
              const SizedBox(height: 8),
              dashboard.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: LoadingView(message: 'Loading dashboard…'),
                ),
                error: (e, _) => SizedBox(
                  height: 200,
                  child: ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(employeeDashboardProvider),
                  ),
                ),
                data: (data) => _DashboardBody(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});
  final EmployeeDashboard data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CheckInCard(dashboard: data),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Today at a glance'),
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
                label: 'Worked hours',
                value: DateFormatter.formatDuration(data.workedDuration),
                icon: Icons.timer_outlined,
                iconColor: AppColors.success,
              ),
              StatCard(
                label: 'Late minutes',
                value: data.lateMinutes.toStringAsFixed(0),
                subtitle: data.lateMinutes > 0 ? 'Today' : 'On time',
                icon: Icons.schedule_outlined,
                iconColor: data.lateMinutes > 0 ? AppColors.warning : AppColors.success,
              ),
              StatCard(
                label: 'Early exit',
                value: data.earlyExitMinutes.toStringAsFixed(0),
                subtitle: data.earlyExitMinutes > 0 ? 'Minutes' : 'No early exits',
                icon: Icons.exit_to_app_outlined,
                iconColor: data.earlyExitMinutes > 0 ? AppColors.warning : AppColors.success,
              ),
              StatCard(
                label: 'Pending tasks',
                value: data.pendingTasks.toString(),
                icon: Icons.task_alt_outlined,
                iconColor: AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: 8),
        const QuickActions(),
        const SizedBox(height: 20),
        if (data.upcomingHoliday != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.celebration, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Upcoming holiday',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.upcomingHoliday!.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormatter.displayDateLong(data.upcomingHoliday!.date),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
