class TaskLeaderboardEntryDto {
  final String userId;
  final String taskId;
  final String? username;
  final double completionPercent;

  const TaskLeaderboardEntryDto({
    required this.userId,
    required this.taskId,
    required this.username,
    required this.completionPercent,
  });

  factory TaskLeaderboardEntryDto.fromMap(Map<String, dynamic> map) {
    return TaskLeaderboardEntryDto(
      userId: map['user_id'] as String,
      taskId: map['task_id'] as String,
      username: map['username'] as String?,
      completionPercent: ((map['completion_percent'] as num?) ?? 0).toDouble(),
    );
  }
}
