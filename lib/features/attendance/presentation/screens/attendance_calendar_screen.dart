import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/attendance_repository.dart';
import '../../data/models/attendance_day.dart';

final _focusedDayProvider = StateProvider.autoDispose<DateTime>((_) => DateTime.now());
final _selectedDayProvider = StateProvider.autoDispose<DateTime?>((_) => null);

class AttendanceCalendarScreen extends ConsumerWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(monthlyAttendanceProvider);
    final focused = ref.watch(_focusedDayProvider);
    final selected = ref.watch(_selectedDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(monthlyAttendanceProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: monthly.when(
        loading: () => const LoadingView(message: 'Loading attendance…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(monthlyAttendanceProvider),
        ),
        data: (data) {
          final byDate = <DateTime, AttendanceDay>{
            for (final d in data.days) DateTime(d.date.year, d.date.month, d.date.day): d,
          };
          final selectedDay = selected == null
              ? null
              : byDate[DateTime(selected.year, selected.month, selected.day)];

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.invalidate(monthlyAttendanceProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: <Widget>[
                _Calendar(
                  focusedDay: focused,
                  selectedDay: selected,
                  byDate: byDate,
                  onPageChanged: (day) {
                    ref.read(_focusedDayProvider.notifier).state = day;
                    ref.read(selectedAttendanceMonthProvider.notifier).state =
                        AttendanceMonth(day.year, day.month);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    ref.read(_selectedDayProvider.notifier).state = selectedDay;
                    ref.read(_focusedDayProvider.notifier).state = focusedDay;
                  },
                ),
                const SizedBox(height: 12),
                if (selectedDay != null) _DayDetailsCard(day: selectedDay),
                if (selectedDay == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap any date to see details.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const SectionHeader(title: 'This month'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: <Widget>[
                      StatCard(
                        label: 'Present',
                        value: data.summary.totalPresent.toString(),
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.success,
                      ),
                      StatCard(
                        label: 'Late',
                        value: data.summary.totalLate.toString(),
                        icon: Icons.schedule_outlined,
                        iconColor: AppColors.warning,
                      ),
                      StatCard(
                        label: 'Absent',
                        value: data.summary.totalAbsent.toString(),
                        icon: Icons.cancel_outlined,
                        iconColor: AppColors.danger,
                      ),
                      StatCard(
                        label: 'Leaves',
                        value: data.summary.totalLeaves.toString(),
                        icon: Icons.event_busy_outlined,
                        iconColor: AppColors.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _Legend(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.byDate,
    required this.onPageChanged,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, AttendanceDay> byDate;
  final void Function(DateTime) onPageChanged;
  final void Function(DateTime, DateTime) onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TableCalendar<AttendanceDay>(
          firstDay: DateTime(DateTime.now().year - 2),
          lastDay: DateTime(DateTime.now().year + 1, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) =>
              selectedDay != null && isSameDay(day, selectedDay),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.all(4),
            todayDecoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700),
            selectedDecoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            weekendTextStyle: TextStyle(color: AppColors.textSecondary),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
            rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ),
          calendarBuilders: CalendarBuilders<AttendanceDay>(
            defaultBuilder: (context, day, _) {
              final entry = byDate[DateTime(day.year, day.month, day.day)];
              if (entry == null || entry.mark == AttendanceMark.none) return null;
              return _CalendarDot(day: day, mark: entry.mark);
            },
          ),
        ),
      ),
    );
  }
}

class _CalendarDot extends StatelessWidget {
  const _CalendarDot({required this.day, required this.mark});
  final DateTime day;
  final AttendanceMark mark;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(mark);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          day.day.toString(),
          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13),
        ),
      ),
    );
  }
}

Color _colorFor(AttendanceMark m) => switch (m) {
      AttendanceMark.present => AppColors.attendancePresent,
      AttendanceMark.late => AppColors.attendanceLate,
      AttendanceMark.halfDay => AppColors.attendanceLate,
      AttendanceMark.absent => AppColors.attendanceAbsent,
      AttendanceMark.onLeave => AppColors.attendanceLeave,
      AttendanceMark.holiday => AppColors.attendanceHoliday,
      AttendanceMark.weeklyOff => AppColors.attendanceHoliday,
      AttendanceMark.none => AppColors.textMuted,
    };

String _labelFor(AttendanceMark m) => switch (m) {
      AttendanceMark.present => 'Present',
      AttendanceMark.late => 'Late',
      AttendanceMark.halfDay => 'Half day',
      AttendanceMark.absent => 'Absent',
      AttendanceMark.onLeave => 'On leave',
      AttendanceMark.holiday => 'Holiday',
      AttendanceMark.weeklyOff => 'Weekly off',
      AttendanceMark.none => '—',
    };

class _DayDetailsCard extends StatelessWidget {
  const _DayDetailsCard({required this.day});
  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(day.mark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelFor(day.mark),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormatter.displayDateLong(day.date),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: _DetailRow(
                  label: 'Check in',
                  value: day.checkIn == null ? '—' : DateFormatter.displayTime(day.checkIn!),
                )),
                Expanded(child: _DetailRow(
                  label: 'Check out',
                  value: day.checkOut == null ? '—' : DateFormatter.displayTime(day.checkOut!),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(child: _DetailRow(
                  label: 'Late',
                  value: '${day.lateMinutes.toStringAsFixed(0)}m',
                )),
                Expanded(child: _DetailRow(
                  label: 'Early exit',
                  value: '${day.earlyExitMinutes.toStringAsFixed(0)}m',
                )),
                Expanded(child: _DetailRow(
                  label: 'Worked',
                  value: '${day.workingHours.toStringAsFixed(1)}h',
                )),
              ],
            ),
            if (day.note.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                day.note,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color)>[
      ('Present', AppColors.attendancePresent),
      ('Late / Early', AppColors.attendanceLate),
      ('Absent', AppColors.attendanceAbsent),
      ('Leave', AppColors.attendanceLeave),
      ('Holiday', AppColors.attendanceHoliday),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          for (final e in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: e.$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(e.$1, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}
