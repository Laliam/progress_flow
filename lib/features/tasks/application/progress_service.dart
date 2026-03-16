import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/task_leaderboard_entry_dto.dart';
import '../data/models/task_progress_log_dto.dart';
import '../data/repositories/supabase_task_repository.dart'
    show taskRepositoryProvider;
import '../data/repositories/task_repository.dart';
import '../domain/task.dart';

class ProgressService {
  final TaskRepository _repository;

  const ProgressService(this._repository);

  // ---------------------------------------------------------------------------
  // Progress logging
  // ---------------------------------------------------------------------------

  /// Validates [delta] and logs a progress entry for [task] by [userId].
  ///
  /// Validation rules:
  /// - [delta] must be non-zero.
  /// - [task] must not already be completed.
  /// - The resulting value must not go below 0.
  Future<void> logProgress({
    required Task task,
    required String userId,
    required double delta,
  }) async {
    if (delta == 0) {
      throw ArgumentError('Progress delta cannot be zero.');
    }

    if (task.isCompleted) {
      throw StateError('Cannot log progress for a completed task.');
    }

    final newValue = task.currentValue + delta;

    if (newValue < 0) {
      throw ArgumentError(
        'Progress cannot reduce a goal below zero.',
      );
    }

    await _repository.logProgress(
      taskId: task.id,
      userId: userId,
      delta: delta,
    );
  }

  // ---------------------------------------------------------------------------
  // Progress streams
  // ---------------------------------------------------------------------------

  /// Emits the ordered list of progress log entries for [taskId] in real time.
  Stream<List<TaskProgressLogDto>> watchProgressLogs(String taskId) =>
      _repository.watchProgressLogs(taskId);

  /// Emits the ranked leaderboard entries for [taskId] in real time.
  Stream<List<TaskLeaderboardEntryDto>> watchLeaderboard(String taskId) =>
      _repository.watchLeaderboard(taskId);

  // ---------------------------------------------------------------------------
  // Progress analytics
  // ---------------------------------------------------------------------------

  /// Returns the total value contributed by [userId] across all log entries
  /// in [logs]. Returns 0 if the user has no entries.
  double totalContributionFor({
    required String userId,
    required List<TaskProgressLogDto> logs,
  }) {
    return logs
        .where((log) => log.userId == userId)
        .fold(0.0, (sum, log) => sum + log.valueAdded);
  }

  /// Returns the number of progress log entries made by [userId] in [logs].
  int entryCountFor({
    required String userId,
    required List<TaskProgressLogDto> logs,
  }) {
    return logs.where((log) => log.userId == userId).length;
  }
}

final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService(ref.watch(taskRepositoryProvider));
});
