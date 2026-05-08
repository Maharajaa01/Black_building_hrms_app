import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../task/data/task_repository.dart';

final _employeesProvider = FutureProvider.autoDispose<List<_EmployeeOption>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final res = await dio.get<Map<String, dynamic>>(
    ApiEndpoints.employee,
    queryParameters: <String, dynamic>{
      'fields': jsonEncode(<String>['name', 'employee_name', 'user_id']),
      'filters': jsonEncode(<List<String>>[
        <String>['status', '=', 'Active'],
      ]),
      'order_by': 'employee_name asc',
      'limit_page_length': 200,
    },
  );
  final data = res.data?['data'];
  if (data is! List) return <_EmployeeOption>[];
  return data
      .whereType<Map<String, dynamic>>()
      .map(_EmployeeOption.fromJson)
      .where((e) => e.userId.isNotEmpty)
      .toList();
});

class _EmployeeOption {
  const _EmployeeOption({required this.name, required this.label, required this.userId});
  final String name;
  final String label;
  final String userId;

  factory _EmployeeOption.fromJson(Map<String, dynamic> json) {
    return _EmployeeOption(
      name: json['name']?.toString() ?? '',
      label: json['employee_name']?.toString() ?? json['name']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
    );
  }
}

class HrTaskCreateScreen extends ConsumerStatefulWidget {
  const HrTaskCreateScreen({super.key});

  @override
  ConsumerState<HrTaskCreateScreen> createState() => _HrTaskCreateScreenState();
}

class _HrTaskCreateScreenState extends ConsumerState<HrTaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _priority = 'Medium';
  DateTime? _dueDate;
  String? _assignedTo;
  bool _busy = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an assignee.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(taskRepositoryProvider).create(
            subject: _subjectCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            priority: _priority,
            assignedTo: _assignedTo!,
            dueDate: _dueDate,
          );
      ref.invalidate(allOpenTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task assigned.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(_employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            AppTextField(
              controller: _subjectCtrl,
              label: 'Subject',
              hint: 'Summarize the task',
              validator: (v) => Validators.required(v, field: 'Subject'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Add details, links, expected outcome',
              maxLines: 6,
              minLines: 4,
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final p in <String>['Low', 'Medium', 'High', 'Urgent'])
                  ChoiceChip(
                    label: Text(p),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                    selectedColor: AppColors.black,
                    labelStyle: TextStyle(
                      color: _priority == p ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Assignee',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            employees.when(
              loading: () => const LinearProgressIndicator(color: AppColors.gold),
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
              data: (list) => DropdownButtonFormField<String>(
                value: _assignedTo,
                items: <DropdownMenuItem<String>>[
                  for (final e in list)
                    DropdownMenuItem<String>(
                      value: e.userId,
                      child: Text('${e.label}  •  ${e.userId}'),
                    ),
                ],
                hint: const Text('Pick an employee'),
                onChanged: (v) => setState(() => _assignedTo = v),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.event, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null ? 'Due date (optional)' : DateFormatter.displayDate(_dueDate!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dueDate == null ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Assign task',
              icon: Icons.send_outlined,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
