import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/task.dart';
import '../models/task_dto.dart';
import '../models/task_leaderboard_entry_dto.dart';
import '../models/task_progress_log_dto.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SupabaseTaskRepository(Supabase.instance.client);
});

class SupabaseTaskRepository implements TaskRepository {
  final SupabaseClient _client;

  const SupabaseTaskRepository(this._client);

  @override
  Stream<List<Task>> watchTasksForUser() {
    // No filter needed — RLS policy returns tasks the user created OR joined.
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('deadline', ascending: true)
        .map(
          (rows) => rows.map((row) => TaskDto.fromMap(row).toDomain()).toList(),
        );
  }

  @override
  Stream<List<Task>> watchPublicGroupTasksExcluding(String userId) {
    // SupabaseStreamBuilder only supports a single .eq() filter.
    // Filter is_public via the stream builder; apply is_group_task client-side.
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .map((rows) {
          return rows
              .where((row) => row['is_group_task'] == true)
              .map((row) => TaskDto.fromMap(row).toDomain())
              .toList();
        });
  }

  @override
  Future<Task> getTaskById(String taskId) async {
    final row = await _client
        .from('tasks')
        .select()
        .eq('id', taskId)
        .single();
    return TaskDto.fromMap(row).toDomain();
  }

  @override
  Future<String> createTask({
    required String creatorId,
    required String title,
    required GoalType goalType,
    required double totalGoalValue,
    required double currentValue,
    required DateTime deadline,
    required TaskPriority priority,
    required bool isGroupTask,
    required bool isPublic,
  }) async {
    final response = await _client
        .from('tasks')
        .insert({
          'creator_id': creatorId,
          'title': title,
          'goal_type': TaskDto.goalTypeToDb(goalType),
          'total_goal_value': totalGoalValue,
          'current_value': currentValue,
          'deadline': deadline.toIso8601String(),
          'priority': TaskDto.priorityToDb(priority),
          'is_group_task': isGroupTask,
          'is_public': isPublic,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  @override
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
  }) {
    return _client
        .from('tasks')
        .update({
          'title': title,
          'goal_type': TaskDto.goalTypeToDb(goalType),
          'total_goal_value': totalGoalValue,
          'current_value': currentValue,
          'deadline': deadline.toIso8601String(),
          'priority': TaskDto.priorityToDb(priority),
          'is_group_task': isGroupTask,
          'is_public': isPublic,
        })
        .eq('id', taskId);
  }

  @override
  Future<void> addParticipant({
    required String taskId,
    required String userId,
  }) {
    return _client.from('task_participants').insert({
      'user_id': userId,
      'task_id': taskId,
    });
  }

  @override
  Future<void> joinTaskById({
    required String taskId,
    required String userId,
  }) async {
    await _client.from('tasks').select('id').eq('id', taskId).single();

    final existingParticipant = await _client
        .from('task_participants')
        .select('id')
        .eq('user_id', userId)
        .eq('task_id', taskId)
        .maybeSingle();

    if (existingParticipant != null) {
      throw Exception('You are already part of this goal');
    }

    await addParticipant(taskId: taskId, userId: userId);
  }

  @override
  Future<void> logProgress({
    required String taskId,
    required String userId,
    required double delta,
  }) async {
    await _client.from('progress_logs').insert({
      'task_id': taskId,
      'user_id': userId,
      'value_added': delta,
    });

    await _client.rpc(
      'increment_task_progress',
      params: {'p_task_id': taskId, 'p_delta': delta},
    );
  }

  @override
  Stream<List<TaskProgressLogDto>> watchProgressLogs(String taskId) {
    return _client
        .from('progress_logs')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(TaskProgressLogDto.fromMap).toList());
  }

  @override
  Stream<List<TaskLeaderboardEntryDto>> watchLeaderboard(String taskId) {
    return _client
        .from('task_participants_view')
        .stream(primaryKey: ['user_id'])
        .eq('task_id', taskId)
        .order('completion_percent', ascending: false)
        .map((rows) => rows.map(TaskLeaderboardEntryDto.fromMap).toList());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('progress_logs').delete().eq('task_id', taskId);
    await _client.from('task_invites').delete().eq('task_id', taskId);
    await _client.from('tasks').delete().eq('id', taskId);
  }

  @override
  Future<String> fetchOrCreateInviteCode({
    required String taskId,
    required String inviterId,
  }) async {
    final existing = await _client
        .from('task_invites')
        .select('code')
        .eq('task_id', taskId)
        .limit(1);

    if (existing.isNotEmpty) {
      return existing.first['code'] as String;
    }

    final code = _generateInviteCode();
    await _client.from('task_invites').insert({
      'code': code,
      'task_id': taskId,
      'inviter_id': inviterId,
    });

    return code;
  }

  @override
  Future<String> resolveInviteCode(String code) async {
    final row = await _client
        .from('task_invites')
        .select('task_id')
        .eq('code', code)
        .maybeSingle();

    if (row == null) {
      throw Exception('Invalid invite code.');
    }
    return row['task_id'] as String;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
