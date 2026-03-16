import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'buddy_widget.dart';

class ProgressCelebration extends StatefulWidget {
  final Buddy buddy;
  final String message;
  final VoidCallback? onDismiss;

  const ProgressCelebration({
    super.key,
    required this.buddy,
    required this.message,
    this.onDismiss,
  });

  @override
  State<ProgressCelebration> createState() => _ProgressCelebrationState();
}

class _ProgressCelebrationState extends State<ProgressCelebration> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
            Colors.yellow,
            Colors.pink,
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BuddyWidget(buddy: widget.buddy, size: 64, animate: true),
              const SizedBox(height: 12),
              Text(
                widget.buddy.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onDismiss,
                child: const Text('Thanks!'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void showProgressCelebration(BuildContext context, Buddy buddy) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ProgressCelebration(
        buddy: buddy,
        message: buddy.cheer,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}
