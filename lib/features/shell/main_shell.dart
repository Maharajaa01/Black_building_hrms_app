import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../auth/presentation/controllers/auth_controller.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isHR = user?.isHR ?? false;
    final location = GoRouterState.of(context).matchedLocation;
    final tabs = isHR ? _hrTabs : _employeeTabs;

    final currentIndex = _indexForLocation(location, tabs);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.divider)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < tabs.length; i++)
                _NavItem(
                  tab: tabs[i],
                  selected: i == currentIndex,
                  onTap: () => context.goNamed(tabs[i].routeName),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _indexForLocation(String loc, List<_Tab> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (loc.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  static const List<_Tab> _employeeTabs = <_Tab>[
    _Tab('Home', Icons.dashboard_outlined, Icons.dashboard_rounded,
        RouteNames.home, RoutePaths.home),
    _Tab('Attendance', Icons.calendar_today_outlined, Icons.calendar_today_rounded,
        RouteNames.attendance, RoutePaths.attendance),
    _Tab('Leaves', Icons.event_busy_outlined, Icons.event_busy_rounded,
        RouteNames.leaves, RoutePaths.leaves),
    _Tab('Tasks', Icons.task_alt_outlined, Icons.task_alt_rounded,
        RouteNames.tasks, RoutePaths.tasks),
    _Tab('More', Icons.more_horiz_outlined, Icons.more_horiz_rounded,
        RouteNames.profile, RoutePaths.profile),
  ];

  static const List<_Tab> _hrTabs = <_Tab>[
    _Tab('Dashboard', Icons.insights_outlined, Icons.insights_rounded,
        RouteNames.hrHome, RoutePaths.hrHome),
    _Tab('Attendance', Icons.fact_check_outlined, Icons.fact_check_rounded,
        RouteNames.hrAttendance, RoutePaths.hrAttendance),
    _Tab('Approvals', Icons.approval_outlined, Icons.approval_rounded,
        RouteNames.hrLeaveApprovals, RoutePaths.hrLeaveApprovals),
    _Tab('Tasks', Icons.assignment_outlined, Icons.assignment_rounded,
        RouteNames.hrTasks, RoutePaths.hrTasks),
    _Tab('More', Icons.more_horiz_outlined, Icons.more_horiz_rounded,
        RouteNames.profile, RoutePaths.profile),
  ];
}

class _Tab {
  const _Tab(this.label, this.icon, this.iconActive, this.routeName, this.path);
  final String label;
  final IconData icon;
  final IconData iconActive;
  final String routeName;
  final String path;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.onTap});
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.black : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.gold.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(selected ? tab.iconActive : tab.icon, color: color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
