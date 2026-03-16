import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/task_providers.dart';

class ProgressLogList extends ConsumerWidget {
  final String taskId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ProgressLogList({
    super.key,
    required this.taskId,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(taskProgressLogsProvider(taskId));

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not load activity: $error')),
      data: (logs) {
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No activity yet.\nAdd your first update above.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: logs.length,
          separatorBuilder: (i, j) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            final value = log.valueAdded;
            final createdAt = log.createdAt;
            final time = MaterialLocalizations.of(context).formatTimeOfDay(
              TimeOfDay.fromDateTime(createdAt),
              alwaysUse24HourFormat: false,
            );
            final date = MaterialLocalizations.of(
              context,
            ).formatMediumDate(createdAt);

            return ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.white.withValues(alpha: 0.02),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.trending_up_rounded, size: 18),
              ),
              title: Text(
                '+${value.toStringAsFixed(1)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '$date • $time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
