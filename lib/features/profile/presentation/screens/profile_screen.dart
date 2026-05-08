import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                    image: (user?.imageUrl ?? '').isNotEmpty
                        ? DecorationImage(image: NetworkImage(user!.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (user?.imageUrl ?? '').isEmpty
                      ? Text(
                          (user?.fullName ?? '?').characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      if ((user?.designation ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user!.designation,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Group(
            title: 'My HR',
            items: <_NavItem>[
              _NavItem(Icons.calendar_today_outlined, 'Attendance', RouteNames.attendance),
              _NavItem(Icons.event_busy_outlined, 'Leaves', RouteNames.leaves),
              _NavItem(Icons.task_alt_outlined, 'Tasks', RouteNames.tasks),
              _NavItem(Icons.receipt_long_outlined, 'Salary slips', RouteNames.salary),
              _NavItem(Icons.beach_access_outlined, 'Holidays', RouteNames.holidays),
            ],
          ),
          if (user?.isHR == true) ...<Widget>[
            const SizedBox(height: 16),
            _Group(
              title: 'HR tools',
              items: <_NavItem>[
                _NavItem(Icons.insights_outlined, 'HR Dashboard', RouteNames.hrHome),
                _NavItem(Icons.fact_check_outlined, 'Attendance management', RouteNames.hrAttendance),
                _NavItem(Icons.approval_outlined, 'Leave approvals', RouteNames.hrLeaveApprovals),
                _NavItem(Icons.assignment_outlined, 'Manage tasks', RouteNames.hrTasks),
                _NavItem(Icons.payments_outlined, 'Payroll overview', RouteNames.hrPayroll),
                _NavItem(Icons.groups_outlined, 'Employees', RouteNames.hrEmployees),
              ],
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You\'ll need to log in again to use the app.'),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});
  final String title;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < items.length; i++) ...<Widget>[
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(items[i].icon, size: 18, color: AppColors.goldDark),
                  ),
                  title: Text(
                    items[i].label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => context.goNamed(items[i].route),
                ),
                if (i != items.length - 1) const Divider(height: 1, indent: 60),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}
