import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/supabase_task_repository.dart'
    show taskRepositoryProvider;
import '../data/repositories/task_repository.dart';
import '../domain/task.dart';

class TaskService {
  final TaskRepository _repository;

  const TaskService(this._repository);

  // ---------------------------------------------------------------------------
  // Task creation
  // ---------------------------------------------------------------------------

  /// Validates inputs and creates a new task, adding the creator as the first
  /// participant. Returns the newly created task's ID.
  Future<String> createTask({
    required String creatorId,
    required String title,
    required GoalType goalType,
    required double totalGoalValue,
    required DateTime deadline,
    required TaskPriority priority,
    required bool isGroupTask,
    required bool isPublic,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    if (totalGoalValue <= 0) throw ArgumentError('Goal value must be greater than zero.');
    if (goalType == GoalType.percent && totalGoalValue > 100) throw ArgumentError('Percent goals cannot exceed 100.');
    if (!deadline.isAfter(DateTime.now())) throw ArgumentError('Deadline must be set in the future.');

    final taskId = await _repository.createTask(
      creatorId: creatorId,
      title: trimmedTitle,
      goalType: goalType,
      totalGoalValue: totalGoalValue,
      currentValue: 0,
      deadline: deadline,
      priority: priority,
      isGroupTask: isGroupTask,
      isPublic: isPublic,
    );

    await _repository.addParticipant(taskId: taskId, userId: creatorId);
    return taskId;
  }

  // ---------------------------------------------------------------------------
  // Task update
  // ---------------------------------------------------------------------------

  /// Validates inputs and updates an existing task.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required GoalType goalType,
    required double totalGoalValue,
    required double currentValue,
    required DateTime deadline,
    required TaskPriority priority,
    required bool isGroupTask,
    required bool isPublic,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    if (totalGoalValue <= 0) throw ArgumentError('Goal value must be greater than zero.');
    if (goalType == GoalType.percent && totalGoalValue > 100) throw ArgumentError('Percent goals cannot exceed 100.');
    if (!deadline.isAfter(DateTime.now())) throw ArgumentError('Deadline must be set in the future.');

    await _repository.updateTask(
      taskId: taskId,
      title: trimmedTitle,
      goalType: goalType,
      totalGoalValue: totalGoalValue,
      currentValue: currentValue,
      deadline: deadline,
      priority: priority,
      isGroupTask: isGroupTask,
      isPublic: isPublic,
    );
  }

  // ---------------------------------------------------------------------------
  // Progress logging
  // ---------------------------------------------------------------------------

  /// Validates [delta] and logs progress for [task].
  ///
  /// Rules:
  /// - Delta must be non-zero.
  /// - For percent-type goals the resulting value must stay within [0, 100].
  Future<void> logProgress({
    required Task task,
    required String userId,
    required double delta,
  }) async {
    if (delta == 0) {
      throw ArgumentError('Progress delta cannot be zero.');
    }
    if (task.goalType == GoalType.percent) {
      final newValue = task.currentValue + delta;
      if (newValue < 0 || newValue > 100) {
        throw ArgumentError(
          'Progress for a percent goal must stay between 0 and 100.',
        );
      }
    }

    await _repository.logProgress(
      taskId: task.id,
      userId: userId,
      delta: delta,
    );
  }

  // ---------------------------------------------------------------------------
  // Task joining
  // ---------------------------------------------------------------------------

  /// Resolves [code] to a task ID, adds [userId] as a participant, and
  /// returns the resolved task ID.
  ///
  /// Throws if the code is invalid or the user is already a participant.
  Future<String> joinTaskWithCode({
    required String code,
    required String userId,
  }) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      throw ArgumentError('Invite code cannot be empty.');
    }

    final taskId = await _repository.resolveInviteCode(trimmedCode);
    await _repository.joinTaskById(taskId: taskId, userId: userId);
    return taskId;
  }

  // ---------------------------------------------------------------------------
  // Task deletion
  // ---------------------------------------------------------------------------

  /// Deletes [task]. Only the creator is permitted to delete a task.
  Future<void> deleteTask({
    required Task task,
    required String userId,
  }) async {
    if (task.creatorId != userId) {
      throw StateError('Only the task creator can delete this task.');
    }

    await _repository.deleteTask(task.id);
  }
}

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(ref.watch(taskRepositoryProvider));
});
