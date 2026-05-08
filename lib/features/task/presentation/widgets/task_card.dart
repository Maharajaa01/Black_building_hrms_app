import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/task_item.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({required this.task, this.onTap, super.key});
  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.urgent => AppColors.danger,
      TaskPriority.high => AppColors.warning,
      TaskPriority.medium => AppColors.info,
      TaskPriority.low => AppColors.textMuted,
    };
    final priorityLabel = switch (task.priority) {
      TaskPriority.urgent => 'Urgent',
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
    };
    final statusLabel = switch (task.status) {
      TaskStatus.open => 'Open',
      TaskStatus.working => 'In Progress',
      TaskStatus.pendingReview => 'In Review',
      TaskStatus.completed => 'Completed',
      TaskStatus.cancelled => 'Cancelled',
      TaskStatus.overdue => 'Overdue',
    };
    final statusColor = switch (task.status) {
      TaskStatus.completed => AppColors.success,
      TaskStatus.cancelled => AppColors.textMuted,
      TaskStatus.overdue => AppColors.danger,
      TaskStatus.working => AppColors.info,
      TaskStatus.pendingReview => AppColors.gold,
      TaskStatus.open => AppColors.warning,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            if (task.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0, 100) / 100,
                backgroundColor: AppColors.surfaceAlt,
                color: task.progress >= 100 ? AppColors.success : AppColors.gold,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                if (task.expectedEnd != null) ...<Widget>[
                  Icon(
                    task.isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
                    size: 12,
                    color: task.isOverdue ? AppColors.danger : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.displayDate(task.expectedEnd!),
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isOverdue ? AppColors.danger : AppColors.textSecondary,
                      fontWeight: task.isOverdue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
