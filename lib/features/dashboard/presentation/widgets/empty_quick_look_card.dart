part of '../dashboard_screen.dart';

class _EmptyQuickLookCard extends StatelessWidget {
  final VoidCallback onNewTap;

  const _EmptyQuickLookCard({required this.onNewTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 32,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'No goals yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first goal and we’ll start tracking your flow.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: onNewTap,
            child: const Text('Start a goal'),
          ),
        ],
      ),
    );
  }
}
