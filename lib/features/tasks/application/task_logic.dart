import 'dart:math';


import '../domain/task.dart';

class DailyTargetResult {
  final double dailyTarget;
  final String label;

  const DailyTargetResult({
    required this.dailyTarget,
    required this.label,
  });
}

DailyTargetResult calculateDailyTarget({
  required double totalGoal,
  required double currentProgress,
  required DateTime? deadline,
  String? unit,
}) {
  if (deadline == null) {
    return const DailyTargetResult(
      dailyTarget: 0,
      label: 'No deadline set',
    );
  }

  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final daysRemaining =
      max(1, deadline.difference(endOfToday).inDays + 1); // inclusive

  final remaining = max(0, totalGoal - currentProgress);
  final perDay = remaining / daysRemaining;

  final unitStr = (unit != null && unit.isNotEmpty) ? ' $unit' : '';

  return DailyTargetResult(
    dailyTarget: perDay,
    label: '${perDay.toStringAsFixed(1)}$unitStr/day · $daysRemaining days left',
  );
}

enum ScheduleStatus { onTrack, behind, completed }

class ScheduleEvaluation {
  final ScheduleStatus status;
  final String message;

  const ScheduleEvaluation({
    required this.status,
    required this.message,
  });
}

ScheduleEvaluation evaluateSchedule({
  required Task task,
  required DateTime? startDate,
}) {
  if (task.isCompleted) {
    return const ScheduleEvaluation(
      status: ScheduleStatus.completed,
      message: 'Goal completed 🎉',
    );
  }
  if (task.deadline == null || startDate == null) {
    return const ScheduleEvaluation(
      status: ScheduleStatus.onTrack,
      message: 'No schedule defined',
    );
  }

  final now = DateTime.now();
  final totalDays =
      max(1, task.deadline!.difference(startDate).inDays + 1); // inclusive
  final daysPassed = min(
    totalDays,
    max(0, now.difference(startDate).inDays + 1),
  );

  final idealDaily = task.totalGoalValue / totalDays;
  final expectedByNow = idealDaily * daysPassed;

  if (task.currentValue + 1e-6 < expectedByNow) {
    final deficit = expectedByNow - task.currentValue;
    return ScheduleEvaluation(
      status: ScheduleStatus.behind,
      message:
          'Behind schedule by ${deficit.toStringAsFixed(1)}. A small nudge might help.',
    );
  }

  return const ScheduleEvaluation(
    status: ScheduleStatus.onTrack,
    message: 'Nicely on track — keep it up!',
  );
}

