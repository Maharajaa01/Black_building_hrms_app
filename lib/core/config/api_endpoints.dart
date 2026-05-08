/// Centralized list of Frappe / ERPNext endpoints used by the app.
///
/// Frappe exposes two main families of REST endpoints:
///   * `/api/method/<dotted.path>`  – Whitelisted Python methods (RPC style)
///   * `/api/resource/<DocType>`    – CRUD on doctypes
///
/// We prefer custom whitelisted methods under `bb_acadamy_admin.api.mobile.*`
/// for screens that need aggregated data (dashboard, attendance summary, etc.)
/// to keep round-trips low.
class ApiEndpoints {
  ApiEndpoints._();

  // ---------- Auth ----------
  static const String login = '/api/method/login';
  static const String logout = '/api/method/logout';
  static const String loggedUser = '/api/method/frappe.auth.get_logged_user';

  // ---------- Custom mobile API namespace ----------
  static const String _mobile = '/api/method/bb_acadamy_admin.api.mobile';

  static const String me = '$_mobile.me';
  static const String employeeDashboard = '$_mobile.employee_dashboard';
  static const String hrDashboard = '$_mobile.hr_dashboard';
  static const String checkIn = '$_mobile.check_in';
  static const String checkOut = '$_mobile.check_out';
  static const String todayCheckinStatus = '$_mobile.today_checkin_status';
  static const String monthlyAttendance = '$_mobile.monthly_attendance';
  static const String myLeaveBalance = '$_mobile.leave_balance';
  static const String applyLeave = '$_mobile.apply_leave';
  static const String approveLeave = '$_mobile.approve_leave';
  static const String mySalarySlips = '$_mobile.my_salary_slips';
  static const String salarySlipDetail = '$_mobile.salary_slip_detail';

  // ---------- Standard Frappe resource endpoints ----------
  static const String employee = '/api/resource/Employee';
  static const String attendance = '/api/resource/Attendance';
  static const String employeeCheckin = '/api/resource/Employee Checkin';
  static const String leaveApplication = '/api/resource/Leave Application';
  static const String leaveType = '/api/resource/Leave Type';
  static const String task = '/api/resource/Task';
  static const String holidayList = '/api/resource/Holiday List';
  static const String salarySlip = '/api/resource/Salary Slip';

  // ---------- File / PDF ----------
  static const String printFormat = '/api/method/frappe.utils.print_format.download_pdf';
}
