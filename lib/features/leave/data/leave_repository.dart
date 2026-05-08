import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_formatter.dart';
import 'models/leave_application.dart';

class LeaveRepository {
  LeaveRepository(this._dio);
  final DioClient _dio;

  Future<List<LeaveApplication>> myLeaves({int limit = 50}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.leaveApplication,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(<String>[
          'name',
          'employee',
          'employee_name',
          'leave_type',
          'from_date',
          'to_date',
          'total_leave_days',
          'description',
          'status',
          'posting_date',
          'leave_approver',
        ]),
        'order_by': 'from_date desc',
        'limit_page_length': limit,
      },
    );

    final data = res.data?['data'];
    if (data is! List) return <LeaveApplication>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LeaveApplication.fromJson)
        .toList();
  }

  /// HR-only — return all pending leaves so the approval queue can render.
  Future<List<LeaveApplication>> pendingLeaves() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.leaveApplication,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(<String>[
          'name',
          'employee',
          'employee_name',
          'leave_type',
          'from_date',
          'to_date',
          'total_leave_days',
          'description',
          'status',
          'posting_date',
          'leave_approver',
        ]),
        'filters': jsonEncode(<List<String>>[
          <String>['status', '=', 'Open'],
        ]),
        'order_by': 'posting_date desc',
        'limit_page_length': 100,
      },
    );

    final data = res.data?['data'];
    if (data is! List) return <LeaveApplication>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LeaveApplication.fromJson)
        .toList();
  }

  Future<List<LeaveType>> leaveTypes() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.leaveType,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(<String>['name', 'max_leaves_allowed']),
        'limit_page_length': 50,
      },
    );
    final data = res.data?['data'];
    if (data is! List) return <LeaveType>[];
    return data.whereType<Map<String, dynamic>>().map(LeaveType.fromJson).toList();
  }

  Future<List<LeaveBalance>> myLeaveBalance() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myLeaveBalance);
    final data = res.data?['message'];
    if (data is! List) return <LeaveBalance>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LeaveBalance.fromJson)
        .toList();
  }

  Future<void> applyLeave({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    bool halfDay = false,
  }) async {
    await _dio.post<dynamic>(
      ApiEndpoints.applyLeave,
      data: <String, dynamic>{
        'leave_type': leaveType,
        'from_date': DateFormatter.toFrappeDate(fromDate),
        'to_date': DateFormatter.toFrappeDate(toDate),
        'description': reason,
        'half_day': halfDay ? 1 : 0,
      },
    );
  }

  Future<void> cancelLeave(String name) async {
    await _dio.put<dynamic>(
      '${ApiEndpoints.leaveApplication}/$name',
      data: <String, dynamic>{'status': 'Cancelled'},
    );
  }

  /// HR-only.
  Future<void> approveLeave(String name, {bool approve = true, String? note}) async {
    await _dio.post<dynamic>(
      ApiEndpoints.approveLeave,
      data: <String, dynamic>{
        'name': name,
        'status': approve ? 'Approved' : 'Rejected',
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(dioClientProvider));
});

final myLeavesProvider = FutureProvider.autoDispose<List<LeaveApplication>>((ref) {
  return ref.watch(leaveRepositoryProvider).myLeaves();
});

final pendingLeavesProvider = FutureProvider.autoDispose<List<LeaveApplication>>((ref) {
  return ref.watch(leaveRepositoryProvider).pendingLeaves();
});

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveType>>((ref) {
  return ref.watch(leaveRepositoryProvider).leaveTypes();
});

final leaveBalanceProvider = FutureProvider.autoDispose<List<LeaveBalance>>((ref) {
  return ref.watch(leaveRepositoryProvider).myLeaveBalance();
});
