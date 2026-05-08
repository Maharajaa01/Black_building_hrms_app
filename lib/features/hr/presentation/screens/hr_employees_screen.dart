import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';

class _Employee {
  _Employee({
    required this.name,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.imageUrl,
    required this.userId,
  });
  final String name;
  final String employeeName;
  final String designation;
  final String department;
  final String imageUrl;
  final String userId;

  factory _Employee.fromJson(Map<String, dynamic> json) {
    return _Employee(
      name: json['name']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
    );
  }
}

final _employeesQueryProvider = StateProvider.autoDispose<String>((_) => '');

final _employeesProvider = FutureProvider.autoDispose<List<_Employee>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final res = await dio.get<Map<String, dynamic>>(
    ApiEndpoints.employee,
    queryParameters: <String, dynamic>{
      'fields': jsonEncode(<String>[
        'name',
        'employee_name',
        'designation',
        'department',
        'image',
        'user_id',
      ]),
      'filters': jsonEncode(<List<String>>[
        <String>['status', '=', 'Active'],
      ]),
      'order_by': 'employee_name asc',
      'limit_page_length': 200,
    },
  );

  final data = res.data?['data'];
  if (data is! List) return <_Employee>[];
  return data.whereType<Map<String, dynamic>>().map(_Employee.fromJson).toList();
});

class HrEmployeesScreen extends ConsumerWidget {
  const HrEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_employeesQueryProvider);
    final employees = ref.watch(_employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employees',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => ref.read(_employeesQueryProvider.notifier).state = v.toLowerCase(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () async => ref.invalidate(_employeesProvider),
              child: employees.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(_employeesProvider),
                ),
                data: (list) {
                  final filtered = query.isEmpty
                      ? list
                      : list
                          .where((e) =>
                              e.employeeName.toLowerCase().contains(query) ||
                              e.designation.toLowerCase().contains(query) ||
                              e.department.toLowerCase().contains(query))
                          .toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      title: 'No employees match',
                      icon: Icons.search_off_outlined,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final emp = filtered[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              image: emp.imageUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(emp.imageUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: emp.imageUrl.isEmpty
                                ? Text(
                                    (emp.employeeName.isNotEmpty ? emp.employeeName : '?')
                                        .characters
                                        .first
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.goldDark,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            emp.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            <String>[
                              if (emp.designation.isNotEmpty) emp.designation,
                              if (emp.department.isNotEmpty) emp.department,
                            ].join(' • '),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
