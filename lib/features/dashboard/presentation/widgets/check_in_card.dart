import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/employee_dashboard.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({required this.dashboard, super.key});
  final EmployeeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final hasIn = dashboard.hasCheckedIn;
    final hasOut = dashboard.hasCheckedOut;

    final headline = hasOut
        ? 'Day completed'
        : hasIn
            ? 'You\'re working'
            : 'Ready to start your day?';

    final sub = hasOut
        ? 'Worked ${DateFormatter.formatDuration(dashboard.workedDuration)}'
        : hasIn
            ? 'Checked in at ${DateFormatter.displayTime(dashboard.checkInTime!)}'
            : 'Tap to check in and start tracking';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasIn && !hasOut ? AppColors.gold : Colors.white60,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasOut
                          ? 'Completed'
                          : hasIn
                              ? 'Working'
                              : 'Not checked in',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormatter.displayDateLong(DateTime.now()),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              if (!hasIn)
                Expanded(
                  child: PrimaryButton(
                    label: 'Check In',
                    icon: Icons.login_rounded,
                    variant: PrimaryButtonVariant.gold,
                    onPressed: () => context.pushNamed(RouteNames.checkin),
                  ),
                ),
              if (hasIn && !hasOut)
                Expanded(
                  child: PrimaryButton(
                    label: 'Check Out',
                    icon: Icons.logout_rounded,
                    variant: PrimaryButtonVariant.gold,
                    onPressed: () => context.pushNamed(RouteNames.checkin),
                  ),
                ),
              if (hasOut)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () => context.goNamed(RouteNames.attendance),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('View attendance'),
                  ),
                ),
            ],
          ),
          if (hasIn) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _Pill(label: 'In', value: DateFormatter.displayTime(dashboard.checkInTime!)),
                const SizedBox(width: 10),
                if (hasOut)
                  _Pill(label: 'Out', value: DateFormatter.displayTime(dashboard.checkOutTime!))
                else
                  const _Pill(label: 'Out', value: '—'),
                const SizedBox(width: 10),
                _Pill(
                  label: 'Late',
                  value: '${dashboard.lateMinutes.toStringAsFixed(0)} m',
                  highlight: dashboard.lateMinutes > 0,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: highlight ? AppColors.gold : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
