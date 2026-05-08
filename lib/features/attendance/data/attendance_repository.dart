import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_formatter.dart';
import 'models/attendance_day.dart';

class CheckInResult {
  const CheckInResult({
    required this.logType,
    required this.time,
    required this.lateMinutes,
    required this.earlyExitMinutes,
  });

  final String logType;
  final DateTime time;
  final double lateMinutes;
  final double earlyExitMinutes;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      logType: json['log_type']?.toString() ?? 'IN',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      lateMinutes: ((json['late_minutes'] as num?) ?? 0).toDouble(),
      earlyExitMinutes: ((json['early_exit_minutes'] as num?) ?? 0).toDouble(),
    );
  }
}

class AttendanceRepository {
  AttendanceRepository(this._dio);
  final DioClient _dio;

  Future<MonthlyAttendance> monthly({required int year, required int month}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.monthlyAttendance,
      queryParameters: <String, dynamic>{'year': year, 'month': month},
    );
    return MonthlyAttendance.fromJson(res.data?['message'] as Map<String, dynamic>);
  }

  Future<CheckInResult> checkIn({
    required double? latitude,
    required double? longitude,
  }) async {
    return _logCheckin(endpoint: ApiEndpoints.checkIn, latitude: latitude, longitude: longitude);
  }

  Future<CheckInResult> checkOut({
    required double? latitude,
    required double? longitude,
  }) async {
    return _logCheckin(endpoint: ApiEndpoints.checkOut, latitude: latitude, longitude: longitude);
  }

  Future<CheckInResult> _logCheckin({
    required String endpoint,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'time': DateFormatter.toFrappeDateTime(DateTime.now()),
      },
    );
    return CheckInResult.fromJson(res.data?['message'] as Map<String, dynamic>);
  }

  /// Today's check-in / check-out summary for the current user.
  Future<Map<String, dynamic>> todayStatus() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.todayCheckinStatus);
    return res.data?['message'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
});

class AttendanceMonth {
  const AttendanceMonth(this.year, this.month);
  final int year;
  final int month;
}

final selectedAttendanceMonthProvider = StateProvider<AttendanceMonth>((_) {
  final now = DateTime.now();
  return AttendanceMonth(now.year, now.month);
});

final monthlyAttendanceProvider =
    FutureProvider.autoDispose<MonthlyAttendance>((ref) {
  final m = ref.watch(selectedAttendanceMonthProvider);
  return ref.watch(attendanceRepositoryProvider).monthly(year: m.year, month: m.month);
});
