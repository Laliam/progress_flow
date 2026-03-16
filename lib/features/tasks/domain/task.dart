import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

class Task extends Equatable {
  final String id;
  final String creatorId;
  final String title;
  final String? unit; // e.g. "km", "pages", "reps", "minutes"
  final double totalGoalValue;
  final double currentValue;
  final DateTime? deadline;
  final TaskPriority priority;
  final bool isGroupTask;
  final bool isPublic;

  const Task({
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

  double get completionPercent {
    if (totalGoalValue <= 0) return 0;
    return (currentValue / totalGoalValue).clamp(0.0, 1.0);
  }

  bool get isCompleted => completionPercent >= 1;

  @override
  List<Object?> get props => [
        id, creatorId, title, unit, totalGoalValue, currentValue,
        deadline, priority, isGroupTask, isPublic,
      ];
}
