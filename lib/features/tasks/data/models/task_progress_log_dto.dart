class TaskProgressLogDto {
  final String id;
  final String taskId;
  final String userId;
  final double valueAdded;
  final DateTime createdAt;

  const TaskProgressLogDto({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.valueAdded,
    required this.createdAt,
  });

  factory TaskProgressLogDto.fromMap(Map<String, dynamic> map) {
    return TaskProgressLogDto(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      userId: map['user_id'] as String,
      valueAdded: (map['value_added'] as num).toDouble(),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
