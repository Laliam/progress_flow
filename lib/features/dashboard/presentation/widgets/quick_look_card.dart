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
            colors: task.isGroupTask
                ? [const Color(0xFF2D3060), const Color(0xFF12141F)]
                : [const Color(0xFF353848), const Color(0xFF181B2C)],
          ),
          border: Border.all(
            color: task.isGroupTask
                ? const Color(0xFF5B63D3)
                : const Color(0xFF3C4055),
            width: task.isGroupTask ? 1.5 : 1,
          ),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B63D3), Color(0xFF7C3AED)],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Group',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
              backgroundColor: const Color(0xFF2F3242),
              progressColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(completion * 100).round()}% complete',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFD0D3E4),
                  ),
                ),
                if (task.deadline != null)
                  Text(
                    'Due ${MaterialLocalizations.of(context).formatMediumDate(task.deadline!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFB8BBCC),
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
