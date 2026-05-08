import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'models/salary_slip.dart';

class SalaryRepository {
  SalaryRepository(this._dio);
  final DioClient _dio;

  Future<List<SalarySlip>> mySlips() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.mySalarySlips);
    final data = res.data?['message'];
    if (data is! List) return <SalarySlip>[];
    return data.whereType<Map<String, dynamic>>().map(SalarySlip.fromJson).toList();
  }

  Future<SalarySlip> detail(String name) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.salarySlipDetail,
      queryParameters: <String, dynamic>{'name': name},
    );
    return SalarySlip.fromJson(res.data?['message'] as Map<String, dynamic>);
  }
}

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  return SalaryRepository(ref.watch(dioClientProvider));
});

final mySalarySlipsProvider = FutureProvider.autoDispose<List<SalarySlip>>((ref) {
  return ref.watch(salaryRepositoryProvider).mySlips();
});

final salarySlipDetailProvider =
    FutureProvider.autoDispose.family<SalarySlip, String>((ref, name) {
  return ref.watch(salaryRepositoryProvider).detail(name);
});
