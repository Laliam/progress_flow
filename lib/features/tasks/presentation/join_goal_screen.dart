import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/task_providers.dart';
import '../application/task_service.dart';
import '../domain/task.dart';

class JoinGoalScreen extends ConsumerStatefulWidget {
  const JoinGoalScreen({super.key});

  @override
  ConsumerState<JoinGoalScreen> createState() => _JoinGoalScreenState();
}

class _JoinGoalScreenState extends ConsumerState<JoinGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _joiningTaskId; // tracks which public task is being joined

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isJoining = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final taskId = await ref
          .read(taskServiceProvider)
          .joinTaskWithCode(code: _codeController.text.trim(), userId: userId);

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.pop();
      context.push('/task/$taskId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not join: $e')));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _joinPublicTask(Task task) async {
    setState(() => _joiningTaskId = task.id);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      await ref
          .read(taskRepositoryProvider)
          .joinTaskById(taskId: task.id, userId: userId);

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.pop();
      context.push('/task/${task.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not join: $e')));
    } finally {
      if (mounted) setState(() => _joiningTaskId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publicTasksAsync = ref.watch(publicGroupTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join a Challenge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Invite-code section ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_add_rounded,
                      size: 52,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Race with friends',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter an invite code below, or browse public challenges anyone can join.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Invite code',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitCode(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'A3BK9XW2',
                    helperText:
                        'Codes are 8 characters — letters and numbers only',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an invite code';
                    }
                    if (value.trim().length < 6) {
                      return 'Code looks too short — double-check it';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isJoining ? null : _submitCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.group_add_rounded),
                  label: Text(
                    _isJoining ? 'Joining...' : 'Join with Code',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or browse public challenges',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Public challenges list ───────────────────────────────
              publicTasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load challenges: $e',
                    style: theme.textTheme.bodySmall),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.public_off_rounded,
                              size: 36,
                              color:
                                  Colors.white.withValues(alpha: 0.25)),
                          const SizedBox(height: 10),
                          Text(
                            'No public challenges yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a group goal and toggle it public so others can join.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: tasks.map((task) {
                      final isJoining = _joiningTaskId == task.id;
                      final daysLeft = task.deadline
                          ?.difference(DateTime.now())
                          .inDays;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PublicChallengeCard(
                          task: task,
                          isJoining: isJoining,
                          daysLeft: daysLeft,
                          onJoin: () => _joinPublicTask(task),
                          theme: theme,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicChallengeCard extends StatelessWidget {
  final Task task;
  final bool isJoining;
  final int? daysLeft;
  final VoidCallback onJoin;
  final ThemeData theme;

  const _PublicChallengeCard({
    required this.task,
    required this.isJoining,
    required this.daysLeft,
    required this.onJoin,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final goalLabel =
        '${task.totalGoalValue.toStringAsFixed(0)} ${task.goalType == GoalType.percent ? '%' : 'units'}';
    final deadlineLabel = task.deadline == null
        ? 'No deadline'
        : daysLeft == null
            ? ''
            : daysLeft! < 0
                ? 'Ended'
                : daysLeft == 0
                    ? 'Ends today'
                    : '$daysLeft days left';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.public_rounded,
              color: theme.colorScheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      goalLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    if (deadlineLabel.isNotEmpty) ...[
                      Text(
                        '  ·  ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      Text(
                        deadlineLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: daysLeft != null && daysLeft! <= 3
                              ? theme.colorScheme.tertiary
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: isJoining ? null : onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(60, 36),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            child: isJoining
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Colors.white),
                  )
                : const Text('Join'),
          ),
        ],
      ),
    );
  }
}

