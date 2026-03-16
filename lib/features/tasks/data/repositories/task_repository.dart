import '../../domain/task.dart';
import '../models/task_leaderboard_entry_dto.dart';
import '../models/task_progress_log_dto.dart';

abstract interface class TaskRepository {
  /// Returns a real-time stream of all tasks visible to the current user
  /// (tasks they created OR joined). Relies on Supabase RLS to filter.
  Stream<List<Task>> watchTasksForUser();

  /// Returns a stream of public group tasks that the given user has NOT joined.
  Stream<List<Task>> watchPublicGroupTasksExcluding(String userId);

  Future<Task> getTaskById(String taskId);

  Future<String> createTask({
    required String creatorId,
    required String title,
    String? unit,
    required double totalGoalValue,
    required double currentValue,
    required DateTime deadline,
    required TaskPriority priority,
    required bool isGroupTask,
    required bool isPublic,
  });

  Future<void> updateTask({
    required String taskId,
    required String title,
    String? unit,
    required double totalGoalValue,
    required double currentValue,
    required DateTime deadline,
    required TaskPriority priority,
    required bool isGroupTask,
    required bool isPublic,
  });

  Future<void> addParticipant({required String taskId, required String userId});

  Future<void> joinTaskById({required String taskId, required String userId});

  Future<void> logProgress({
    required String taskId,
    required String userId,
    required double delta,
  });

  Stream<List<TaskProgressLogDto>> watchProgressLogs(String taskId);

  Stream<List<TaskLeaderboardEntryDto>> watchLeaderboard(String taskId);

  Future<void> deleteTask(String taskId);

  Future<String> fetchOrCreateInviteCode({
    required String taskId,
    required String inviterId,
  });

  /// Looks up a task ID by its invite code. Throws if the code is not found.
  Future<String> resolveInviteCode(String code);
}
