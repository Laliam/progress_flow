import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/progress_service.dart';
import '../../application/task_providers.dart';
import '../../domain/task.dart';

class ProgressQuickActions extends ConsumerStatefulWidget {
  final Task task;

  const ProgressQuickActions({super.key, required this.task});

  @override
  ConsumerState<ProgressQuickActions> createState() =>
      _ProgressQuickActionsState();
}

class _ProgressQuickActionsState extends ConsumerState<ProgressQuickActions> {
  final _valueController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _logProgress() async {
    final delta = double.tryParse(_valueController.text);
    if (delta == null || delta <= 0) return;

    setState(() => _isUpdating = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      await ref
          .read(progressServiceProvider)
          .logProgress(task: widget.task, userId: userId, delta: delta);
      ref.invalidate(taskByIdProvider(widget.task.id));

      HapticFeedback.mediumImpact();
      if (mounted) {
        _valueController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress logged')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not log progress: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.isCompleted;
    final isPercent = widget.task.goalType == GoalType.percent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.secondary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: isCompleted
          ? Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Goal completed! 🎉',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: isPercent ? 'Add % (e.g. 10)' : 'Add amount (e.g. 25)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _isUpdating ? null : _logProgress,
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
