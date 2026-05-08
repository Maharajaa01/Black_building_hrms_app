import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/models/task_item.dart';
import '../../data/task_repository.dart';
import '../widgets/task_card.dart';

final _taskFilterProvider = StateProvider.autoDispose<_TaskFilter>((_) => _TaskFilter.active);

enum _TaskFilter { active, completed, all }

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksProvider);
    final filter = ref.watch(_taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myTasksProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<_TaskFilter>(
              segments: const <ButtonSegment<_TaskFilter>>[
                ButtonSegment<_TaskFilter>(
                  value: _TaskFilter.active,
                  label: Text('Active'),
                ),
                ButtonSegment<_TaskFilter>(
                  value: _TaskFilter.completed,
                  label: Text('Completed'),
                ),
                ButtonSegment<_TaskFilter>(
                  value: _TaskFilter.all,
                  label: Text('All'),
                ),
              ],
              selected: <_TaskFilter>{filter},
              onSelectionChanged: (s) => ref.read(_taskFilterProvider.notifier).state = s.first,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textStyle: const WidgetStatePropertyAll<TextStyle>(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected) ? AppColors.black : null,
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected) ? AppColors.gold : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(myTasksProvider),
        child: tasksAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(myTasksProvider),
          ),
          data: (tasks) {
            final filtered = _applyFilter(tasks, filter);
            if (filtered.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No tasks here',
                    message: 'Tasks assigned to you will appear here.',
                    icon: Icons.task_alt_outlined,
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final task = filtered[i];
                return TaskCard(
                  task: task,
                  onTap: () => context.pushNamed(
                    RouteNames.taskDetail,
                    pathParameters: <String, String>{'taskId': task.name},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<TaskItem> _applyFilter(List<TaskItem> tasks, _TaskFilter f) {
    switch (f) {
      case _TaskFilter.active:
        return tasks
            .where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.cancelled)
            .toList();
      case _TaskFilter.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case _TaskFilter.all:
        return tasks;
    }
  }
}
