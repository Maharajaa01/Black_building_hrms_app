import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/leave_repository.dart';
import '../widgets/leave_card.dart';

class LeavesScreen extends ConsumerWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(myLeavesProvider);
    final balances = ref.watch(leaveBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaves'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(myLeavesProvider);
              ref.invalidate(leaveBalanceProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.applyLeave),
        icon: const Icon(Icons.add),
        label: const Text('Apply'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.invalidate(myLeavesProvider);
          ref.invalidate(leaveBalanceProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: <Widget>[
            balances.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => list.isEmpty ? const SizedBox.shrink() : _BalancesRow(balances: list),
            ),
            const SizedBox(height: 12),
            leaves.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: LoadingView(),
              ),
              error: (e, _) => ErrorView(
                message: e is ApiException ? e.message : e.toString(),
                onRetry: () => ref.invalidate(myLeavesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: EmptyState(
                      title: 'No leaves yet',
                      message: 'Apply for your first leave using the button below.',
                      icon: Icons.event_busy_outlined,
                      action: ElevatedButton.icon(
                        onPressed: () => context.pushNamed(RouteNames.applyLeave),
                        icon: const Icon(Icons.add),
                        label: const Text('Apply leave'),
                      ),
                    ),
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final leave in list) ...<Widget>[
                      LeaveCard(
                        leave: leave,
                        onCancel: () async {
                          final ok = await _confirmCancel(context);
                          if (!ok) return;
                          try {
                            await ref.read(leaveRepositoryProvider).cancelLeave(leave.name);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Leave cancelled.')),
                              );
                            }
                            ref.invalidate(myLeavesProvider);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel leave?'),
        content: const Text('This will mark the request as cancelled.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel leave'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

class _BalancesRow extends StatelessWidget {
  const _BalancesRow({required this.balances});
  final List balances;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (_, i) {
          final b = balances[i];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  b.leaveType,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      b.balance.toStringAsFixed(b.balance % 1 == 0 ? 0 : 1),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'days',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
