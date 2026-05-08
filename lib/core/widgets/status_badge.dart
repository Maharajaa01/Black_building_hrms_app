import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  factory StatusBadge.forStatus(String status) {
    final s = status.toLowerCase();
    final color = switch (s) {
      'present' || 'completed' || 'approved' || 'success' => AppColors.success,
      'late' || 'pending' || 'open' || 'warning' || 'on hold' => AppColors.warning,
      'absent' || 'rejected' || 'cancelled' || 'failed' => AppColors.danger,
      'on leave' || 'in progress' || 'working' => AppColors.info,
      'holiday' || 'draft' => AppColors.textMuted,
      _ => AppColors.textSecondary,
    };
    return StatusBadge(label: status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
