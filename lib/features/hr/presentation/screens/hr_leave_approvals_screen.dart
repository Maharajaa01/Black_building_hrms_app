import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../dashboard/data/dashboard_repository.dart';
import '../../../leave/data/leave_repository.dart';
import '../../../leave/data/models/leave_application.dart';
import '../../../leave/presentation/widgets/leave_card.dart';

class HrLeaveApprovalsScreen extends ConsumerWidget {
  const HrLeaveApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingLeavesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave approvals')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(pendingLeavesProvider),
        child: pending.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(pendingLeavesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'All caught up',
                    message: 'No leave requests are waiting for your approval.',
                    icon: Icons.check_circle_outline,
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final leave = list[i];
                return LeaveCard(
                  leave: leave,
                  showEmployee: true,
                  trailing: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.divider),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () => _decide(context, ref, leave, approve: false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () => _decide(context, ref, leave, approve: true),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    LeaveApplication leave, {
    required bool approve,
  }) async {
    final note = await _promptNote(context, approve: approve);
    if (note == null) return;

    try {
      await ref.read(leaveRepositoryProvider).approveLeave(
            leave.name,
            approve: approve,
            note: note,
          );
      ref.invalidate(pendingLeavesProvider);
      ref.invalidate(hrDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Leave approved.' : 'Leave rejected.'),
            backgroundColor: approve ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<String?> _promptNote(BuildContext context, {required bool approve}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve leave' : 'Reject leave'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: approve ? 'Add a note (optional)' : 'Reason for rejection (optional)',
          ),
          maxLines: 3,
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    return result;
  }
}
