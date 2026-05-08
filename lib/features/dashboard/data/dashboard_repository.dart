import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'models/employee_dashboard.dart';
import 'models/hr_dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final DioClient _dio;

  Future<EmployeeDashboard> employeeDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.employeeDashboard);
    return EmployeeDashboard.fromJson(res.data?['message'] as Map<String, dynamic>);
  }

  Future<HrDashboard> hrDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.hrDashboard);
    return HrDashboard.fromJson(res.data?['message'] as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioClientProvider));
});

final employeeDashboardProvider = FutureProvider.autoDispose<EmployeeDashboard>((ref) {
  return ref.watch(dashboardRepositoryProvider).employeeDashboard();
});

final hrDashboardProvider = FutureProvider.autoDispose<HrDashboard>((ref) {
  return ref.watch(dashboardRepositoryProvider).hrDashboard();
});
