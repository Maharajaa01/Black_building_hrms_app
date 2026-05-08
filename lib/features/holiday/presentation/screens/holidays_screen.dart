import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/holiday_repository.dart';

class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(myHolidaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(myHolidaysProvider),
        child: holidaysAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(myHolidaysProvider),
          ),
          data: (holidays) {
            final upcoming = holidays.where((h) => h.isUpcoming && !h.weeklyOff).toList();
            if (holidays.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No holidays found',
                    message: 'No holiday list is assigned to you yet.',
                    icon: Icons.beach_access_outlined,
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                if (upcoming.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat('d\nMMM').format(upcoming.first.date),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'NEXT HOLIDAY',
                                style: TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: 1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                upcoming.first.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                DateFormatter.displayDateLong(upcoming.first.date),
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'All holidays',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < holidays.length; i++) ...<Widget>[
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: holidays[i].weeklyOff
                                  ? AppColors.surfaceAlt
                                  : AppColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              DateFormat('d').format(holidays[i].date),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: holidays[i].weeklyOff ? AppColors.textMuted : AppColors.goldDark,
                              ),
                            ),
                          ),
                          title: Text(
                            holidays[i].description,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormatter.displayDateLong(holidays[i].date),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: holidays[i].weeklyOff
                              ? const Text('Weekly off',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted))
                              : null,
                        ),
                        if (i != holidays.length - 1) const Divider(height: 1, indent: 60),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
