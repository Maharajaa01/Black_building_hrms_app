import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../dashboard/data/dashboard_repository.dart';
import '../../data/leave_repository.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String? _leaveType;
  DateTime? _from;
  DateTime? _to;
  bool _halfDay = false;
  bool _busy = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  double get _totalDays {
    if (_from == null || _to == null) return 0;
    if (_to!.isBefore(_from!)) return 0;
    final days = _to!.difference(_from!).inDays + 1;
    return _halfDay ? 0.5 : days.toDouble();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_from ?? DateTime.now()) : (_to ?? _from ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_leaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a leave type.')),
      );
      return;
    }
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select from and to dates.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(leaveRepositoryProvider).applyLeave(
            leaveType: _leaveType!,
            fromDate: _from!,
            toDate: _to!,
            reason: _reasonCtrl.text.trim(),
            halfDay: _halfDay,
          );
      ref.invalidate(myLeavesProvider);
      ref.invalidate(leaveBalanceProvider);
      ref.invalidate(employeeDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave submitted. Awaiting approval.'),
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
    final types = ref.watch(leaveTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for leave')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Leave type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            types.when(
              loading: () => const LinearProgressIndicator(color: AppColors.gold),
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final t in list)
                    ChoiceChip(
                      label: Text(t.name),
                      selected: _leaveType == t.name,
                      onSelected: (_) => setState(() => _leaveType = t.name),
                      selectedColor: AppColors.black,
                      labelStyle: TextStyle(
                        color: _leaveType == t.name ? AppColors.gold : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateBox(
                    label: 'From',
                    value: _from,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateBox(
                    label: 'To',
                    value: _to,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _halfDay,
              onChanged: (v) => setState(() => _halfDay = v),
              title: const Text('Half day'),
              subtitle: const Text('Counts as 0.5 leave day', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.schedule, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_totalDays.toStringAsFixed(_totalDays % 1 == 0 ? 0 : 1)} day${_totalDays > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _reasonCtrl,
              label: 'Reason',
              hint: 'Briefly explain the reason for leave',
              maxLines: 5,
              minLines: 3,
              validator: (v) => Validators.required(v, field: 'Reason'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit application',
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

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  value == null ? 'Select date' : DateFormatter.displayDate(value!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

