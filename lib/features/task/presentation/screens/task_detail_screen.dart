import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/task_item.dart';
import '../../data/task_repository.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({required this.taskId, super.key});
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _setProgress(double progress) async {
    setState(() => _busy = true);
    try {
      await ref.read(taskRepositoryProvider).updateProgress(
            name: widget.taskId,
            progress: progress,
            status: progress >= 100 ? 'Completed' : 'Working',
          );
      ref.invalidate(taskDetailProvider(widget.taskId));
      ref.invalidate(myTasksProvider);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(taskRepositoryProvider).addComment(name: widget.taskId, comment: text);
      _commentCtrl.clear();
      _toast('Comment added.');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: taskAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
        ),
        data: (task) => SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            task.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        StatusBadge.forStatus(_statusLabel(task.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _Chip(icon: Icons.flag_outlined, label: _priorityLabel(task.priority)),
                        if (task.expectedEnd != null)
                          _Chip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Due ${DateFormatter.displayDate(task.expectedEnd!)}',
                          ),
                        if (task.project.isNotEmpty)
                          _Chip(icon: Icons.folder_outlined, label: task.project),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (task.description.isNotEmpty) ...<Widget>[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${task.progress.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: task.progress.clamp(0, 100) / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceAlt,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              for (final p in <int>[25, 50, 75, 100])
                                OutlinedButton(
                                  onPressed: _busy ? null : () => _setProgress(p.toDouble()),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  child: Text('$p%'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (task.status != TaskStatus.completed) ...<Widget>[
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Mark as completed',
                        icon: Icons.check_circle_outline,
                        loading: _busy,
                        variant: PrimaryButtonVariant.success,
                        onPressed: () => _setProgress(100),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.gold,
                        ),
                        onPressed: _busy ? null : _submitComment,
                        icon: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus s) => switch (s) {
        TaskStatus.completed => 'Completed',
        TaskStatus.cancelled => 'Cancelled',
        TaskStatus.overdue => 'Overdue',
        TaskStatus.working => 'In Progress',
        TaskStatus.pendingReview => 'In Review',
        TaskStatus.open => 'Open',
      };

  String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.urgent => 'Urgent',
        TaskPriority.high => 'High priority',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low priority',
      };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
