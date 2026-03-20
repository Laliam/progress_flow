import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../../auth/application/auth_service.dart';
import '../../tasks/application/task_service.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/application/task_logic.dart';
import '../../tasks/application/task_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../shared/widgets/responsive_layout.dart';

part 'widgets/quick_look_card.dart';
part 'widgets/empty_quick_look_card.dart';

enum GoalSortBy { deadline, name, priority, completion }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  GoalSortBy _sortBy = GoalSortBy.deadline;
  bool _sortAsc = true;
  bool _showCompleted = true;

  List<Task> _sortTasks(List<Task> tasks) {
    var list = _showCompleted ? tasks : tasks.where((t) => !t.isCompleted).toList();
    list = List.of(list);
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case GoalSortBy.deadline:
          final aD = a.deadline ?? DateTime(9999);
          final bD = b.deadline ?? DateTime(9999);
          cmp = aD.compareTo(bD);
        case GoalSortBy.name:
          cmp = a.title.compareTo(b.title);
        case GoalSortBy.priority:
          int ps(Task t) => switch (t.priority) {
            TaskPriority.high => 0,
            TaskPriority.medium => 1,
            TaskPriority.low => 2,
          };
          cmp = ps(a).compareTo(ps(b));
        case GoalSortBy.completion:
          cmp = a.completionPercent.compareTo(b.completionPercent);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForCurrentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UpTrack'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: ClipOval(
              child: AvatarPlus(
                ref.watch(currentProfileProvider).valueOrNull?.avatarSeed ??
                    ref.watch(currentUserIdProvider) ?? 'user',
                height: 36,
                width: 36,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                HapticFeedback.selectionClick();
                context.go('/welcome');
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/task/new');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksForCurrentUserProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
        child: MaxWidthBox(
          padding: EdgeInsets.fromLTRB(
            isTablet(context) ? 32 : 16,
            8,
            isTablet(context) ? 32 : 16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick look',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Quick-look: horizontal scroll on phone, 2-col grid on tablet
              isTablet(context)
                  ? tasksAsync.when(
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return _EmptyQuickLookCard(
                              onNewTap: () => context.push('/task/new'));
                        }
                        tasks.sort((a, b) {
                          int ps(Task t) => switch (t.priority) {
                                TaskPriority.high => 0,
                                TaskPriority.medium => 1,
                                TaskPriority.low => 2,
                              };
                          final pri = ps(a).compareTo(ps(b));
                          if (pri != 0) return pri;
                          return (a.deadline ?? DateTime(9999))
                              .compareTo(b.deadline ?? DateTime(9999));
                        });
                        return ResponsiveGrid(
                          phoneColumns: 1,
                          tabletColumns: 2,
                          spacing: 14,
                          runSpacing: 14,
                          children: tasks
                              .take(6)
                              .map((t) => Hero(
                                    tag: 'task-card-${t.id}',
                                    child: _QuickLookCard(task: t),
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    )
                  : SizedBox(
                      height: 190,
                      child: tasksAsync.when(
                        data: (tasks) {
                          if (tasks.isEmpty) {
                            return _EmptyQuickLookCard(
                                onNewTap: () => context.push('/task/new'));
                          }
                          tasks.sort((a, b) {
                            int priorityScore(Task t) => switch (t.priority) {
                                  TaskPriority.high => 0,
                                  TaskPriority.medium => 1,
                                  TaskPriority.low => 2,
                                };
                            final pri =
                                priorityScore(a).compareTo(priorityScore(b));
                            if (pri != 0) return pri;
                            final aDeadline = a.deadline ??
                                DateTime.now()
                                    .add(const Duration(days: 365));
                            final bDeadline = b.deadline ??
                                DateTime.now()
                                    .add(const Duration(days: 365));
                            return aDeadline.compareTo(bDeadline);
                          });

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tasks.length,
                      separatorBuilder: (i, j) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Hero(
                          tag: 'task-card-${task.id}',
                          child: _QuickLookCard(task: task),
                        );
                      },
                    );
                  },
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (i, j) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        const _ShimmerQuickLookCard(),
                  ),
                  error: (error, _) =>
                      Center(child: Text('Could not load tasks: $error')),
                ),
              ), // SizedBox (phone quick-look)
              const SizedBox(height: 14),

              // ── Join a Group Challenge ──────────────────────────────
              const _JoinChallengeCard(),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All goals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/task/new');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              // ── Sort/filter row ──────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Show completed'),
                      selected: _showCompleted,
                      onSelected: (v) => setState(() => _showCompleted = v),
                    ),
                    const SizedBox(width: 8),
                    ...GoalSortBy.values.map((s) {
                      final label = switch (s) {
                        GoalSortBy.deadline => 'Deadline',
                        GoalSortBy.name => 'Name',
                        GoalSortBy.priority => 'Priority',
                        GoalSortBy.completion => '% Done',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label),
                              if (_sortBy == s) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  _sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          selected: _sortBy == s,
                          onSelected: (_) => setState(() {
                            if (_sortBy == s) {
                              _sortAsc = !_sortAsc;
                            } else {
                              _sortBy = s;
                              _sortAsc = true;
                            }
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return _EmptyAllGoalsWidget(
                        onNewTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/task/new');
                        },
                      );
                    }
                    final sorted = _sortTasks(tasks);
                    if (sorted.isEmpty) {
                      return Center(
                        child: Text(
                          'All goals completed! 🎉',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    // Build the individual goal card widget
                    Widget goalCard(Task task) {
                      final schedule = evaluateSchedule(
                        task: task,
                        startDate: task.deadline
                            ?.subtract(const Duration(days: 30)),
                      );
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/task/${task.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: task.isGroupTask
                                ? const Color(0xFF1A1D36)
                                : const Color(0xFF1C1F2E),
                            border: Border.all(
                              color: task.isGroupTask
                                  ? const Color(0xFF5B63D3)
                                  : const Color(0xFF2A2D40),
                              width: task.isGroupTask ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircularPercentIndicator(
                                radius: 24,
                                lineWidth: 5,
                                percent: task.completionPercent,
                                backgroundColor: const Color(0xFF2A2D40),
                                progressColor: switch (schedule.status) {
                                  ScheduleStatus.completed =>
                                    theme.colorScheme.secondary,
                                  ScheduleStatus.behind =>
                                    theme.colorScheme.tertiary,
                                  _ => theme.colorScheme.primary,
                                },
                                center: Text(
                                  '${(task.completionPercent * 100).round()}%',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          task.isGroupTask
                                              ? Icons.groups_rounded
                                              : Icons.person_rounded,
                                          size: 14,
                                          color: task.isGroupTask
                                              ? const Color(0xFF7986CB)
                                              : const Color(0xFF78909C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.isGroupTask
                                              ? 'Group'
                                              : 'Personal',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: task.isGroupTask
                                                ? const Color(0xFF7986CB)
                                                : const Color(0xFF78909C),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      schedule.message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: const Color(0xFFB8BBCC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PriorityBadge(priority: task.priority),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isTablet(context)) {
                      return ResponsiveGrid(
                        phoneColumns: 1,
                        tabletColumns: 2,
                        spacing: 12,
                        runSpacing: 12,
                        children: sorted.map(goalCard).toList(),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sorted.length,
                      separatorBuilder: (i, j) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return goalCard(sorted[index]);
                      },
                    );
                  },
                  loading: () => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    separatorBuilder: (i, j) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        const _ShimmerAllGoalsCard(),
                  ),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (priority) {
      TaskPriority.low => ('Low', const Color(0xFF22C55E)),
      TaskPriority.medium => ('Med', const Color(0xFFFACC15)),
      TaskPriority.high => ('High', const Color(0xFFFB7185)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerQuickLookCard extends StatelessWidget {
  const _ShimmerQuickLookCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF22253A),
      highlightColor: const Color(0xFF2E3248),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF353848),
              const Color(0xFF181B2C),
            ],
          ),
          border: Border.all(color: const Color(0xFF3C4055)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF22253A),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 20, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(width: 150, height: 20, color: Colors.white),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 14, color: Colors.white),
                Container(width: 80, height: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerAllGoalsCard extends StatelessWidget {
  const _ShimmerAllGoalsCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF22253A),
      highlightColor: const Color(0xFF2E3248),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF1C1F2E),
          border: Border.all(color: const Color(0xFF2A2D3E)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 14, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF22253A),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 20, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAllGoalsWidget extends StatelessWidget {
  final VoidCallback onNewTap;

  const _EmptyAllGoalsWidget({required this.onNewTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to achieve greatness?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set your first goal and watch your progress soar. Every journey starts with a single step!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB8BBCC),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onNewTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Your First Goal'),
          ),
        ],
      ),
    );
  }
}

// ── Inline join-challenge card ─────────────────────────────────────────────

class _JoinChallengeCard extends ConsumerStatefulWidget {
  const _JoinChallengeCard();

  @override
  ConsumerState<_JoinChallengeCard> createState() => _JoinChallengeCardState();
}

class _JoinChallengeCardState extends ConsumerState<_JoinChallengeCard> {
  final _codeController = TextEditingController();
  bool _expanded = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isJoining = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final taskId = await ref
          .read(taskServiceProvider)
          .joinTaskWithCode(code: code, userId: userId);

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.push('/task/$taskId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not join: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1C1F2E),
        border: Border.all(
          color: _expanded
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : const Color(0xFF2F3242),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _expanded
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = true);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _expanded ? _buildExpanded(theme) : _buildCollapsed(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          ),
          child: Icon(
            Icons.group_add_rounded,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join a Group Challenge',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Enter an invite code to race with friends',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8B8FA8),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: const Color(0xFF6B7080),
        ),
      ],
    );
  }

  Widget _buildExpanded(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.group_add_rounded,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Join a Group Challenge',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = false;
                  _codeController.clear();
                });
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: const Color(0xFF6B7080),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _join(),
                decoration: const InputDecoration(
                  hintText: 'e.g.  A3BK9XW2',
                  labelText: 'Invite code',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _isJoining ? null : _join,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                minimumSize: const Size(0, 48),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
      ],
    );
  }
}
