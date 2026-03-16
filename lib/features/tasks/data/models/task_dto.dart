import '../../domain/task.dart';

class TaskDto {
  final String id;
  final String creatorId;
  final String title;
  final String? unit;
  final double totalGoalValue;
  final double currentValue;
  final DateTime? deadline;
  final String priority;
  final bool isGroupTask;
  final bool isPublic;

  const TaskDto({
    required this.id,
    required this.creatorId,
    required this.title,
    this.unit,
    required this.totalGoalValue,
    required this.currentValue,
    required this.deadline,
    required this.priority,
    required this.isGroupTask,
    required this.isPublic,
  });

  factory TaskDto.fromMap(Map<String, dynamic> map) {
    return TaskDto(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      title: map['title'] as String,
      unit: map['unit'] as String?,
      totalGoalValue: (map['total_goal_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      deadline: _parseDateTime(map['deadline']),
      priority: map['priority'] as String? ?? 'Med',
      isGroupTask: (map['is_group_task'] as bool?) ?? false,
      isPublic: (map['is_public'] as bool?) ?? false,
    );
  }

  Task toDomain() {
    return Task(
      id: id,
      creatorId: creatorId,
      title: title,
      unit: unit,
      totalGoalValue: totalGoalValue,
      currentValue: currentValue,
      deadline: deadline,
      priority: switch (priority) {
        'Low' => TaskPriority.low,
        'Med' => TaskPriority.medium,
        'High' => TaskPriority.high,
        _ => TaskPriority.medium,
      },
      isGroupTask: isGroupTask,
      isPublic: isPublic,
    );
  }

  static String priorityToDb(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Med',
      TaskPriority.high => 'High',
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
