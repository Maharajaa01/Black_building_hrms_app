enum UserRole { employee, hrManager, admin, unknown }

class AuthUser {
  const AuthUser({
    required this.username,
    required this.email,
    required this.fullName,
    required this.employeeId,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.imageUrl,
    required this.holidayList,
    required this.role,
    required this.roles,
  });

  final String username;
  final String email;
  final String fullName;
  final String employeeId;
  final String employeeName;
  final String designation;
  final String department;
  final String imageUrl;
  final String holidayList;
  final UserRole role;
  final List<String> roles;

  bool get isHR => role == UserRole.hrManager || role == UserRole.admin;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((dynamic e) => e.toString()).toList()
        : <String>[];

    return AuthUser(
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      employeeId: json['employee']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      holidayList: json['holiday_list']?.toString() ?? '',
      roles: roles,
      role: _resolveRole(roles),
    );
  }

  static UserRole _resolveRole(List<String> roles) {
    if (roles.contains('System Manager') || roles.contains('Administrator')) {
      return UserRole.admin;
    }
    if (roles.contains('HR Manager') || roles.contains('HR User')) {
      return UserRole.hrManager;
    }
    if (roles.contains('Employee')) return UserRole.employee;
    return UserRole.unknown;
  }
}
