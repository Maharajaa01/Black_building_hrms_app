import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'models/holiday.dart';

class HolidayRepository {
  HolidayRepository(this._dio);
  final DioClient _dio;

  /// Reads a Holiday List doc and returns its child `holidays` rows.
  Future<List<Holiday>> readList(String holidayList) async {
    if (holidayList.isEmpty) return <Holiday>[];

    final res = await _dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.holidayList}/${Uri.encodeComponent(holidayList)}',
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) return <Holiday>[];
    final holidays = data['holidays'];
    if (holidays is! List) return <Holiday>[];
    return holidays
        .whereType<Map<String, dynamic>>()
        .map(Holiday.fromJson)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Falls back to the first available Holiday List when the user has none
  /// assigned (e.g. service accounts during testing).
  Future<List<Holiday>> firstAvailable() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.holidayList,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(<String>['name']),
        'limit_page_length': 1,
      },
    );
    final data = res.data?['data'];
    if (data is! List || data.isEmpty) return <Holiday>[];
    final first = data.first as Map<String, dynamic>;
    return readList(first['name'].toString());
  }
}

final holidayRepositoryProvider = Provider<HolidayRepository>((ref) {
  return HolidayRepository(ref.watch(dioClientProvider));
});

final myHolidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) async {
  final repo = ref.watch(holidayRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user != null && user.holidayList.isNotEmpty) {
    return repo.readList(user.holidayList);
  }
  return repo.firstAvailable();
});
