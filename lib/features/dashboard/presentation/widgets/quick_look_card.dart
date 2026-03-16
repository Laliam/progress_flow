part of '../dashboard_screen.dart';

class _QuickLookCard extends StatelessWidget {
  final Task task;

  const _QuickLookCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completion = task.completionPercent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/task/${task.id}');
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PriorityBadge(priority: task.priority),
                if (task.isGroupTask)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text('Race Mode', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8,
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(999),
              percent: completion,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              progressColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(completion * 100).round()}% complete',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (task.deadline != null)
                  Text(
                    'Due ${MaterialLocalizations.of(context).formatMediumDate(task.deadline!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
