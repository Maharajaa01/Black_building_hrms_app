import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/screens/attendance_calendar_screen.dart';
import '../../features/attendance/presentation/screens/checkin_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/hr_dashboard_screen.dart';
import '../../features/holiday/presentation/screens/holidays_screen.dart';
import '../../features/hr/presentation/screens/hr_attendance_screen.dart';
import '../../features/hr/presentation/screens/hr_employees_screen.dart';
import '../../features/hr/presentation/screens/hr_leave_approvals_screen.dart';
import '../../features/hr/presentation/screens/hr_payroll_screen.dart';
import '../../features/hr/presentation/screens/hr_task_create_screen.dart';
import '../../features/hr/presentation/screens/hr_tasks_screen.dart';
import '../../features/leave/presentation/screens/apply_leave_screen.dart';
import '../../features/leave/presentation/screens/leaves_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/salary/presentation/screens/salary_detail_screen.dart';
import '../../features/salary/presentation/screens/salary_slips_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/task/presentation/screens/task_detail_screen.dart';
import '../../features/task/presentation/screens/tasks_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final status = authState.status;
      final loc = state.matchedLocation;

      final isLoggingIn = loc == RoutePaths.login;
      final isSplash = loc == RoutePaths.splash;

      if (status == AuthStatus.unknown) {
        return isSplash ? null : RoutePaths.splash;
      }
      if (status == AuthStatus.authenticated) {
        if (isLoggingIn || isSplash) {
          return authState.user?.isHR == true ? RoutePaths.hrHome : RoutePaths.home;
        }
        return null;
      }
      // unauthenticated / error
      if (!isLoggingIn) return RoutePaths.login;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.checkin,
        name: RouteNames.checkin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CheckInScreen(),
      ),
      GoRoute(
        path: RoutePaths.applyLeave,
        name: RouteNames.applyLeave,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: RoutePaths.taskDetail,
        name: RouteNames.taskDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => TaskDetailScreen(
          taskId: state.pathParameters['taskId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.salaryDetail,
        name: RouteNames.salaryDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SalaryDetailScreen(
          slipId: state.pathParameters['slipId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.hrTaskCreate,
        name: RouteNames.hrTaskCreate,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const HrTaskCreateScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: EmployeeDashboardScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.attendance,
            name: RouteNames.attendance,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: AttendanceCalendarScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.leaves,
            name: RouteNames.leaves,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: LeavesScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.tasks,
            name: RouteNames.tasks,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: TasksScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.salary,
            name: RouteNames.salary,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: SalarySlipsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.holidays,
            name: RouteNames.holidays,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HolidaysScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: ProfileScreen(),
            ),
          ),
          // HR routes (still inside the shell so the bottom nav stays)
          GoRoute(
            path: RoutePaths.hrHome,
            name: RouteNames.hrHome,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrDashboardScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.hrAttendance,
            name: RouteNames.hrAttendance,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrAttendanceScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.hrLeaveApprovals,
            name: RouteNames.hrLeaveApprovals,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrLeaveApprovalsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.hrTasks,
            name: RouteNames.hrTasks,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrTasksScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.hrPayroll,
            name: RouteNames.hrPayroll,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrPayrollScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.hrEmployees,
            name: RouteNames.hrEmployees,
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: HrEmployeesScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
});

/// Adapter that lets `go_router` listen to a Riverpod [authControllerProvider].
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
