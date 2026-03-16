import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../application/task_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String taskId;

  const LeaderboardScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(taskLeaderboardProvider(taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Race Mode')),
      body: SafeArea(
        child: leaderboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load race: $error')),
          data: (rows) {
            if (rows.isEmpty) {
              return Center(
                child: Text(
                  'Invite friends to start a race on this goal.',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // ── Bar Chart ─────────────────────────────────────────
                _ParticipantBarChart(rows: rows, theme: theme),
                const SizedBox(height: 20),

                // ── Leaderboard list ──────────────────────────────────
                ...rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final username = row.username ?? 'Someone';
                  final percent = row.completionPercent;
                  final isTop3 = index < 3;

                  Color? medalColor;
                  if (index == 0) {
                    medalColor = const Color(0xFFFFD700);
                  } else if (index == 1) {
                    medalColor = const Color(0xFFC0C0C0);
                  } else if (index == 2) {
                    medalColor = const Color(0xFFCD7F32);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: isTop3
                          ? medalColor!.withValues(alpha: 0.2)
                          : const Color(0xFF1A1D2B),
                      leading: CircleAvatar(
                        radius: isTop3 ? 24 : 20,
                        backgroundColor: isTop3
                            ? medalColor
                            : const Color(0xFF2A2D40),
                        child: isTop3
                            ? const Icon(Icons.emoji_events, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: theme.textTheme.labelLarge,
                              ),
                      ),
                      title: Text(
                        username,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isTop3 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearPercentIndicator(
                          lineHeight: 8,
                          padding: EdgeInsets.zero,
                          barRadius: const Radius.circular(999),
                          percent: percent.clamp(0, 1),
                          backgroundColor:
                              const Color(0xFF2A2D40),
                          progressColor: isTop3
                              ? medalColor!
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      trailing: Text(
                        '${(percent * 100).round()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Participant bar chart ──────────────────────────────────────────────────

class _ParticipantBarChart extends StatelessWidget {
  final List<dynamic> rows;
  final ThemeData theme;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  const _ParticipantBarChart({required this.rows, required this.theme});

  Color _barColor(int index) {
    if (index == 0) return _gold;
    if (index == 1) return _silver;
    if (index == 2) return _bronze;
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = rows.asMap().entries.map((e) {
      final pct =
          (e.value.completionPercent * 100).clamp(0, 100).toDouble();
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: _barColor(e.key),
            width: 22,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1C1F2E),
        border: Border.all(color: const Color(0xFF2A2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Text(
              'Completion by participant',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD8DBE8),
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 105,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, meta) {
                        if (v > 100) return const SizedBox.shrink();
                        return Text(
                          '${v.round()}%',
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
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        final idx = v.round();
                        if (idx < 0 || idx >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        final name =
                            (rows[idx].username ?? '?') as String;
                        final short = name.length > 7
                            ? '${name.substring(0, 6)}…'
                            : name;
                        return Text(
                          short,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surface.withValues(alpha: 0.9),
                    getTooltipItem: (group, gi, rod, ri) {
                      final name =
                          rows[group.x].username ?? '?';
                      return BarTooltipItem(
                        '$name\n${rod.toY.round()}%',
                        theme.textTheme.labelSmall!.copyWith(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
