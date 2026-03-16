import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/models/task_leaderboard_entry_dto.dart';
import '../data/models/task_progress_log_dto.dart';
import '../data/repositories/supabase_task_repository.dart';
import '../domain/task.dart';

export '../data/repositories/supabase_task_repository.dart'
    show taskRepositoryProvider;
export '../../auth/application/auth_provider.dart' show currentUserIdProvider;

final tasksForCurrentUserProvider = StreamProvider.autoDispose<List<Task>>((
  ref,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Stream.empty();
  }

  return ref.watch(taskRepositoryProvider).watchTasksForUser();
});

final taskByIdProvider = FutureProvider.family.autoDispose<Task, String>((
  ref,
  taskId,
) {
  return ref.watch(taskRepositoryProvider).getTaskById(taskId);
});

final taskProgressLogsProvider = StreamProvider.family
    .autoDispose<List<TaskProgressLogDto>, String>((ref, taskId) {
      return ref.watch(taskRepositoryProvider).watchProgressLogs(taskId);
    });

final taskLeaderboardProvider = StreamProvider.family
    .autoDispose<List<TaskLeaderboardEntryDto>, String>((ref, taskId) {
      return ref.watch(taskRepositoryProvider).watchLeaderboard(taskId);
    });

final taskInviteCodeProvider = FutureProvider.family
    .autoDispose<String, String>((ref, taskId) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      return ref
          .watch(taskRepositoryProvider)
          .fetchOrCreateInviteCode(taskId: taskId, inviterId: userId);
    });

final publicGroupTasksProvider =
    StreamProvider.autoDispose<List<Task>>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const Stream.empty();
      return ref
          .watch(taskRepositoryProvider)
          .watchPublicGroupTasksExcluding(userId);
    });
