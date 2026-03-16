import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/task_logic.dart';
import '../application/task_providers.dart';
import '../application/task_service.dart';
import '../domain/task.dart';

class TaskCreationScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const TaskCreationScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends ConsumerState<TaskCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalGoalController = TextEditingController();
  final _currentValueController = TextEditingController(text: '0');
  DateTime? _deadline;
  GoalType _goalType = GoalType.numerical;
  TaskPriority _priority = TaskPriority.medium;
  bool _isGroupTask = false;
  bool _isPublic = false;
  bool _isSaving = false;

  DailyTargetResult? _dailyTarget;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _totalGoalController.text = task.totalGoalValue.toString();
      _currentValueController.text = task.currentValue.toString();
      _deadline = task.deadline;
      _goalType = task.goalType;
      _priority = task.priority;
      _isGroupTask = task.isGroupTask;
      _isPublic = task.isPublic;
      _recalculatePreview();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalGoalController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  void _recalculatePreview() {
    final total = double.tryParse(_totalGoalController.text) ?? 0;
    final current = double.tryParse(_currentValueController.text) ?? 0;
    setState(() {
      _dailyTarget = calculateDailyTarget(
        totalGoal: total,
        currentProgress: current,
        deadline: _deadline,
      );
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Select deadline',
    );
    if (selected != null) {
      // Use end of selected day so "today" passes the future-deadline validation.
      setState(() => _deadline = DateTime(
            selected.year,
            selected.month,
            selected.day,
            23,
            59,
            59,
          ));
      _recalculatePreview();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a deadline to unlock smart targets.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('Not authenticated');
      }
      final service = ref.read(taskServiceProvider);

      final totalGoal = double.parse(_totalGoalController.text);
      final currentValue = double.tryParse(_currentValueController.text) ?? 0;

      if (widget.taskToEdit != null) {
        await service.updateTask(
          taskId: widget.taskToEdit!.id,
          title: _titleController.text.trim(),
          goalType: _goalType,
          totalGoalValue: totalGoal,
          currentValue: currentValue,
          deadline: _deadline!,
          priority: _priority,
          isGroupTask: _isGroupTask,
          isPublic: _isPublic,
        );

        HapticFeedback.heavyImpact();
        if (!mounted) return;
        ref.invalidate(taskByIdProvider(widget.taskToEdit!.id));
        context.pop(); // Go back to detail screen
      } else {
        final taskId = await service.createTask(
          creatorId: userId,
          title: _titleController.text.trim(),
          goalType: _goalType,
          totalGoalValue: totalGoal,
          deadline: _deadline!,
          priority: _priority,
          isGroupTask: _isGroupTask,
          isPublic: _isPublic,
        );

        HapticFeedback.heavyImpact();
        if (!mounted) return;
        // Pop the creation modal back to dashboard, then push the detail
        // screen so the back button in task detail returns to dashboard.
        context.pop();
        context.push('/task/$taskId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${widget.taskToEdit == null ? 'create' : 'update'} task: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'New Goal' : 'Edit Goal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            onChanged: _recalculatePreview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Goal title',
                    hintText: 'Read 1000 pages',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Give your goal a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<GoalType>(
                        initialValue: _goalType,
                        decoration: const InputDecoration(
                          labelText: 'Goal type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GoalType.numerical,
                            child: Text('Numerical'),
                          ),
                          DropdownMenuItem(
                            value: GoalType.percent,
                            child: Text('Percent'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _goalType = value);
                          _recalculatePreview();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TaskPriority.low,
                            child: Text('Low'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.medium,
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.high,
                            child: Text('High'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _priority = value);
                          _recalculatePreview();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalGoalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _goalType == GoalType.numerical
                        ? 'Total amount'
                        : 'Target percent (0-100)',
                    hintText: _goalType == GoalType.numerical ? '1000' : '100',
                  ),
                  validator: (value) {
                    final v = double.tryParse(value ?? '');
                    if (v == null || v <= 0) {
                      return 'Enter a positive number';
                    }
                    if (_goalType == GoalType.percent && (v <= 0 || v > 100)) {
                      return 'Percent must be between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentValueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Current progress',
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Deadline'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _deadline == null
                              ? 'Tap to choose'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_deadline!),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Group goal'),
                  subtitle: const Text(
                    'Invite others and unlock Race Mode leaderboard',
                  ),
                  value: _isGroupTask,
                  onChanged: (value) {
                    setState(() {
                      _isGroupTask = value;
                      if (!value) _isPublic = false;
                    });
                  },
                ),
                if (_isGroupTask) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: const Text('Public challenge'),
                    subtitle: const Text(
                      'Anyone can discover and join without an invite code',
                    ),
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
                const SizedBox(height: 20),
                if (_dailyTarget != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart daily target',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dailyTarget!.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: Text(
                      _isSaving
                          ? (widget.taskToEdit == null
                                ? 'Creating...'
                                : 'Updating...')
                          : (widget.taskToEdit == null
                                ? 'Create goal'
                                : 'Update goal'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
