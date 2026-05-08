/// All named routes used by `go_router`. Keep paths and names in one place
/// so deep links and `context.goNamed(...)` calls stay consistent.
class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = 'splash';
  static const String login = 'login';

  // Shell
  static const String home = 'home';
  static const String hrHome = 'hr-home';

  // Employee
  static const String attendance = 'attendance';
  static const String checkin = 'checkin';
  static const String leaves = 'leaves';
  static const String applyLeave = 'apply-leave';
  static const String tasks = 'tasks';
  static const String taskDetail = 'task-detail';
  static const String salary = 'salary';
  static const String salaryDetail = 'salary-detail';
  static const String holidays = 'holidays';
  static const String profile = 'profile';

  // HR
  static const String hrAttendance = 'hr-attendance';
  static const String hrLeaveApprovals = 'hr-leave-approvals';
  static const String hrTasks = 'hr-tasks';
  static const String hrPayroll = 'hr-payroll';
  static const String hrEmployees = 'hr-employees';
  static const String hrTaskCreate = 'hr-task-create';
}

class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';

  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String checkin = '/checkin';
  static const String leaves = '/leaves';
  static const String applyLeave = '/leaves/apply';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:taskId';
  static const String salary = '/salary';
  static const String salaryDetail = '/salary/:slipId';
  static const String holidays = '/holidays';
  static const String profile = '/profile';

  // HR
  static const String hrHome = '/hr/home';
  static const String hrAttendance = '/hr/attendance';
  static const String hrLeaveApprovals = '/hr/leaves';
  static const String hrTasks = '/hr/tasks';
  static const String hrTaskCreate = '/hr/tasks/new';
  static const String hrPayroll = '/hr/payroll';
  static const String hrEmployees = '/hr/employees';
}
