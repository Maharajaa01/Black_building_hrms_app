import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/leave_application.dart';

class LeaveCard extends StatelessWidget {
  const LeaveCard({
    required this.leave,
    this.onTap,
    this.onCancel,
    this.trailing,
    this.showEmployee = false,
    super.key,
  });

  final LeaveApplication leave;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final Widget? trailing;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (leave.status) {
      LeaveStatus.approved => AppColors.success,
      LeaveStatus.rejected => AppColors.danger,
      LeaveStatus.cancelled => AppColors.textMuted,
      LeaveStatus.open => AppColors.warning,
    };
    final statusLabel = switch (leave.status) {
      LeaveStatus.approved => 'Approved',
      LeaveStatus.rejected => 'Rejected',
      LeaveStatus.cancelled => 'Cancelled',
      LeaveStatus.open => 'Pending',
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.event_note, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        leave.leaveType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (showEmployee && leave.employeeName.isNotEmpty)
                        Text(
                          leave.employeeName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        )
                      else
                        Text(
                          '${leave.totalLeaveDays.toStringAsFixed(leave.totalLeaveDays % 1 == 0 ? 0 : 1)} day${leave.totalLeaveDays > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Icon(Icons.calendar_today, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${DateFormatter.displayDate(leave.fromDate)} → ${DateFormatter.displayDate(leave.toDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (leave.reason.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                leave.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(height: 12),
              trailing!,
            ],
            if (onCancel != null && leave.isPending) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Cancel request'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
