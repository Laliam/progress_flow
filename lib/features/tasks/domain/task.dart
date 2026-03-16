import 'package:equatable/equatable.dart';

enum GoalType { numerical, percent }

enum TaskPriority { low, medium, high }

class Task extends Equatable {
  final String id;
  final String creatorId;
  final String title;
  final GoalType goalType;
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
    required this.goalType,
    required this.totalGoalValue,
    required this.currentValue,
    required this.deadline,
    required this.priority,
    required this.isGroupTask,
    required this.isPublic,
  });

  double get completionPercent {
    if (totalGoalValue <= 0) return 0;
    final pct = currentValue / totalGoalValue;
    if (goalType == GoalType.percent) {
      return (currentValue / 100).clamp(0, 1);
    }
    return pct.clamp(0, 1);
  }

  bool get isCompleted => completionPercent >= 1;

  @override
  List<Object?> get props => [
        id,
        creatorId,
        title,
        goalType,
        totalGoalValue,
        currentValue,
        deadline,
        priority,
        isGroupTask,
        isPublic,
      ];
}

