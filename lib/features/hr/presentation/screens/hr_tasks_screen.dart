import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../task/data/task_repository.dart';
import '../../../task/presentation/widgets/task_card.dart';

class HrTasksScreen extends ConsumerWidget {
  const HrTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allOpenTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.hrTaskCreate),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(allOpenTasksProvider),
        child: tasksAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(allOpenTasksProvider),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No open tasks',
                    message: 'Create a task to assign work to your team.',
                    icon: Icons.assignment_outlined,
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => TaskCard(
                task: tasks[i],
                onTap: () => context.pushNamed(
                  RouteNames.taskDetail,
                  pathParameters: <String, String>{'taskId': tasks[i].name},
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
