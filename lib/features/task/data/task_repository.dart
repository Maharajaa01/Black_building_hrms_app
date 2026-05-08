import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'models/task_item.dart';

class TaskRepository {
  TaskRepository(this._dio);
  final DioClient _dio;

  static const _fields = <String>[
    'name',
    'subject',
    'description',
    'status',
    'priority',
    'progress',
    'exp_start_date',
    'exp_end_date',
    '_assign',
    'owner',
    'project',
  ];

  /// All tasks assigned to the given user. Frappe stores assignments in
  /// the `_assign` JSON list field, so we filter with a `like` clause.
  Future<List<TaskItem>> myTasks({required String username}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.task,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(_fields),
        'filters': jsonEncode(<List<String>>[
          <String>['_assign', 'like', '%$username%'],
        ]),
        'order_by': 'modified desc',
        'limit_page_length': 100,
      },
    );
    return _parseList(res.data);
  }

  Future<List<TaskItem>> allOpen() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.task,
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(_fields),
        'filters': jsonEncode(<List<String>>[
          <String>['status', 'in', 'Open,Working,Pending Review'],
        ]),
        'order_by': 'modified desc',
        'limit_page_length': 200,
      },
    );
    return _parseList(res.data);
  }

  Future<TaskItem> get(String name) async {
    final res = await _dio.get<Map<String, dynamic>>('${ApiEndpoints.task}/$name');
    return TaskItem.fromJson(res.data?['data'] as Map<String, dynamic>);
  }

  Future<void> updateProgress({
    required String name,
    double? progress,
    String? status,
  }) async {
    await _dio.put<dynamic>(
      '${ApiEndpoints.task}/$name',
      data: <String, dynamic>{
        if (progress != null) 'progress': progress,
        if (status != null) 'status': status,
      },
    );
  }

  Future<void> markCompleted(String name) async {
    await updateProgress(name: name, progress: 100, status: 'Completed');
  }

  Future<void> addComment({required String name, required String comment}) async {
    await _dio.post<dynamic>(
      '/api/method/frappe.desk.form.utils.add_comment',
      data: <String, dynamic>{
        'reference_doctype': 'Task',
        'reference_name': name,
        'content': comment,
        'comment_email': '',
        'comment_by': '',
      },
    );
  }

  Future<void> create({
    required String subject,
    required String description,
    required String priority,
    required String assignedTo,
    DateTime? dueDate,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.task,
      data: <String, dynamic>{
        'subject': subject,
        'description': description,
        'priority': priority,
        'status': 'Open',
        if (dueDate != null) 'exp_end_date': DateFormatter.toFrappeDate(dueDate),
      },
    );
    final taskName = res.data?['data']?['name'] as String?;
    if (taskName != null && assignedTo.isNotEmpty) {
      await _dio.post<dynamic>(
        '/api/method/frappe.desk.form.assign_to.add',
        data: <String, dynamic>{
          'assign_to': jsonEncode(<String>[assignedTo]),
          'doctype': 'Task',
          'name': taskName,
        },
      );
    }
  }

  List<TaskItem> _parseList(dynamic data) {
    final list = data is Map<String, dynamic> ? data['data'] : null;
    if (list is! List) return <TaskItem>[];
    return list.whereType<Map<String, dynamic>>().map(TaskItem.fromJson).toList();
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioClientProvider));
});

final myTasksProvider = FutureProvider.autoDispose<List<TaskItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <TaskItem>[];
  return ref.watch(taskRepositoryProvider).myTasks(username: user.username);
});

final allOpenTasksProvider = FutureProvider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(taskRepositoryProvider).allOpen();
});

final taskDetailProvider =
    FutureProvider.autoDispose.family<TaskItem, String>((ref, name) {
  return ref.watch(taskRepositoryProvider).get(name);
});
