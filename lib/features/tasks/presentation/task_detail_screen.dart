import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../domain/task.dart';
import '../application/task_logic.dart';
import '../application/task_providers.dart';
import '../application/task_service.dart';
import 'widgets/progress_log_list.dart';
import 'widgets/progress_quick_actions.dart';
import 'widgets/task_invite_sheet.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));

    return taskAsync.when(
      data: (task) => _TaskDetailBody(task: task),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

class _TaskDetailBody extends ConsumerWidget {
  final Task task;
  const _TaskDetailBody({required this.task});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(taskServiceProvider)
            .deleteTask(task: task, userId: userId!);
        if (context.mounted) context.go('/dashboard');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final schedule = evaluateSchedule(
      task: task,
      startDate: task.deadline?.subtract(const Duration(days: 30)),
    );
    final dailyTarget = calculateDailyTarget(
      totalGoal: task.totalGoalValue,
      currentProgress: task.currentValue,
      deadline: task.deadline,
      unit: task.unit,
    );

    final unit = task.unit != null && task.unit!.isNotEmpty ? ' ${task.unit}' : '';
    final remaining =
        (task.totalGoalValue - task.currentValue).clamp(0.0, double.infinity);
    final deadlineStr = task.deadline == null
        ? 'No deadline'
        : DateFormat.MMMd().format(task.deadline!);
    final daysLeft = task.deadline?.difference(DateTime.now()).inDays.clamp(0, 9999);

    final progressColor = switch (schedule.status) {
      ScheduleStatus.completed => theme.colorScheme.secondary,
      ScheduleStatus.behind => theme.colorScheme.tertiary,
      _ => theme.colorScheme.primary,
    };

    return Scaffold(
      appBar: AppBar(
        // Always show explicit back: pop if possible, else go to dashboard.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (task.creatorId == userId)
            IconButton(
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/task/${task.id}/edit', extra: task),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (task.creatorId == userId)
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
          if (task.isGroupTask) ...[
            IconButton(
              tooltip: 'Invite',
              onPressed: () => showTaskInviteSheet(context, taskId: task.id),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
            IconButton(
              tooltip: 'Leaderboard',
              onPressed: () => context.push('/task/${task.id}/leaderboard'),
              icon: const Icon(Icons.emoji_events_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress Chart ──────────────────────────────────────
              Hero(
                tag: 'task-card-${task.id}',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF1C1F2E),
                    border: Border.all(
                      color: const Color(0xFF343750),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 84,
                        lineWidth: 12,
                        percent: task.completionPercent,
                        backgroundColor:
                            const Color(0xFF2F3242),
                        progressColor: progressColor,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(task.completionPercent * 100).round()}%',
                              style:
                                  theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: progressColor,
                              ),
                            ),
                            Text(
                              'complete',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF8B8FA8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        schedule.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: schedule.status == ScheduleStatus.behind
                              ? theme.colorScheme.tertiary
                              : const Color(0xFFBEC1D2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (task.deadline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          dailyTarget.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8B8FA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Progress Chart (fl_chart) ────────────────────────────
              _ProgressChart(
                task: task,
                progressColor: progressColor,
                theme: theme,
              ),

              const SizedBox(height: 14),

              // ── Stats Row ────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    label: 'Progress',
                    value:
                        '${task.currentValue.toStringAsFixed(1)}$unit',
                    sub: 'of ${task.totalGoalValue.toStringAsFixed(1)}$unit',
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Remaining',
                    value: '${remaining.toStringAsFixed(1)}$unit',
                    sub: remaining <= 0 ? 'done!' : 'to go',
                    theme: theme,
                    highlightColor:
                        remaining <= 0 ? theme.colorScheme.secondary : null,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Deadline',
                    value: deadlineStr,
                    sub: daysLeft == null
                        ? ''
                        : daysLeft == 0
                            ? 'today'
                            : '$daysLeft days left',
                    theme: theme,
                    highlightColor: daysLeft != null && daysLeft <= 3
                        ? theme.colorScheme.tertiary
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Update Progress ──────────────────────────────────────
              ProgressQuickActions(task: task),

              const SizedBox(height: 22),

              // ── Recent Activity ──────────────────────────────────────
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ProgressLogList(
                taskId: task.id,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final ThemeData theme;
  final Color? highlightColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.theme,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = highlightColor ?? Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: highlightColor != null
              ? highlightColor!.withValues(alpha: 0.08)
              : const Color(0xFF1C1F2E),
          border: Border.all(
            color: highlightColor != null
                ? highlightColor!.withValues(alpha: 0.25)
                : const Color(0xFF2A2D40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF8B8FA8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (highlightColor ?? Colors.white)
                      .withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Progress line chart ────────────────────────────────────────────────────

enum _ChartType { line, bar, pie }

class _ProgressChart extends ConsumerStatefulWidget {
  final Task task;
  final Color progressColor;
  final ThemeData theme;

  const _ProgressChart({
    required this.task,
    required this.progressColor,
    required this.theme,
  });

  @override
  ConsumerState<_ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends ConsumerState<_ProgressChart> {
  _ChartType _chartType = _ChartType.line;

  Task get task => widget.task;
  Color get progressColor => widget.progressColor;
  ThemeData get theme => widget.theme;

  List<FlSpot> _spots(List<dynamic> logs, String? userId, DateTime origin) {
    final filtered = userId == null
        ? logs
        : logs.where((l) => l.userId == userId).toList();
    if (filtered.isEmpty) return [];
    final sorted = [...filtered]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    double cumulative = 0;
    final spots = <FlSpot>[FlSpot(0, 0)];
    for (final log in sorted) {
      if (log.valueAdded <= 0) continue;
      cumulative = (cumulative + log.valueAdded)
          .clamp(0, task.totalGoalValue)
          .toDouble();
      final x =
          log.createdAt.difference(origin).inMinutes / 1440.0;
      spots.add(FlSpot(x.clamp(0, double.infinity), cumulative));
    }
    return spots;
  }

  Widget _buildLineChart(List<dynamic> logs) {
    final sorted = [...logs]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final origin = sorted.first.createdAt.subtract(const Duration(hours: 1));
    final aggregateSpots = _spots(logs, null, origin);
    final myUserId = ref.read(currentUserIdProvider);
    final uniqueUsers = logs.map((l) => l.userId).toSet();
    final showMyLine =
        task.isGroupTask && uniqueUsers.length > 1 && myUserId != null;
    final mySpots =
        showMyLine ? _spots(logs, myUserId, origin) : <FlSpot>[];
    final maxY = task.totalGoalValue * 1.05;
    final totalDays = aggregateSpots.isEmpty
        ? 1.0
        : aggregateSpots.last.x.clamp(1.0, double.infinity);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: totalDays,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: task.totalGoalValue / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: task.totalGoalValue / 4,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.max) return const SizedBox.shrink();
                      return Text(
                        v >= 1000
                            ? '${(v / 1000).toStringAsFixed(1)}k'
                            : v.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6B7080),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: (totalDays / 3)
                        .ceilToDouble()
                        .clamp(1, double.infinity),
                    getTitlesWidget: (v, meta) {
                      final date = origin.add(
                          Duration(minutes: (v * 1440).round()));
                      return Text(
                        DateFormat.MMMd().format(date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6B7080),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: aggregateSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: progressColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: progressColor.withValues(alpha: 0.10),
                  ),
                ),
                if (showMyLine && mySpots.length > 1)
                  LineChartBarData(
                    spots: mySpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: theme.colorScheme.tertiary,
                    barWidth: 1.8,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        if (task.isGroupTask) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: progressColor, label: 'Group total'),
              const SizedBox(width: 14),
              _LegendDot(
                color: theme.colorScheme.tertiary,
                label: 'My progress',
                dashed: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> logs) {
    final sorted = [...logs]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = sorted.length > 10
        ? sorted.sublist(sorted.length - 10)
        : sorted;
    final barGroups = recent.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (e.value.valueAdded as num)
                .toDouble()
                .clamp(0, task.totalGoalValue),
            color: progressColor,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                (task.totalGoalValue / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= recent.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormat.MMMd().format(recent[idx].createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6B7080),
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max) return const SizedBox.shrink();
                  return Text(
                    v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1)}k'
                        : v.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6B7080),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<dynamic> logs) {
    final done = logs.fold<double>(
        0, (sum, l) => sum + (l.valueAdded as num).toDouble());
    final completed = done.clamp(0, task.totalGoalValue).toDouble();
    final remaining =
        (task.totalGoalValue - completed).clamp(0, double.infinity);
    final pct = task.totalGoalValue > 0
        ? (completed / task.totalGoalValue * 100).toStringAsFixed(1)
        : '0';

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: completed,
                  color: progressColor,
                  radius: 24,
                  showTitle: false,
                ),
                PieChartSectionData(
                value: remaining > 0 ? remaining.toDouble() : 0.001,
                  color: const Color(0xFF2F3242),
                  radius: 24,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
              Text(
                'done',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF6B7080),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(taskProgressLogsProvider(task.id));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1C1F2E),
        border: Border.all(color: const Color(0xFF2F3242)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 16, color: progressColor),
              const SizedBox(width: 6),
              Text(
                'Progress chart',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD8DBE8),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13151F),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChartTypeBtn(
                      icon: Icons.show_chart_rounded,
                      selected: _chartType == _ChartType.line,
                      onTap: () =>
                          setState(() => _chartType = _ChartType.line),
                    ),
                    _ChartTypeBtn(
                      icon: Icons.bar_chart_rounded,
                      selected: _chartType == _ChartType.bar,
                      onTap: () =>
                          setState(() => _chartType = _ChartType.bar),
                    ),
                    _ChartTypeBtn(
                      icon: Icons.donut_large_rounded,
                      selected: _chartType == _ChartType.pie,
                      onTap: () =>
                          setState(() => _chartType = _ChartType.pie),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          logsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => SizedBox(
              height: 80,
              child: Center(
                child: Text('Could not load chart',
                    style: theme.textTheme.bodySmall),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'Log some progress to see the chart',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                );
              }
              return switch (_chartType) {
                _ChartType.line => _buildLineChart(logs),
                _ChartType.bar => _buildBarChart(logs),
                _ChartType.pie => _buildPieChart(logs),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _ChartTypeBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChartTypeBtn(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: selected ? const Color(0xFF6C63FF) : const Color(0xFF6B7080)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border: dashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF8B8FA8),
              ),
        ),
      ],
    );
  }
}