import 'package:flutter/material.dart';

class Buddy {
  final IconData icon;
  final Color color;
  final String name;
  final String cheer;
  const Buddy({
    required this.icon,
    required this.color,
    required this.name,
    required this.cheer,
  });
}

const kBuddies = [
  Buddy(icon: Icons.pets,                   color: Color(0xFFFF8A65), name: 'Foxy',    cheer: "You're on fire! Keep going!"),
  Buddy(icon: Icons.local_fire_department,  color: Color(0xFFEF5350), name: 'Drake',   cheer: 'Legendary progress!'),
  Buddy(icon: Icons.spa,                    color: Color(0xFF66BB6A), name: 'Koala',   cheer: 'Slow and steady wins the race!'),
  Buddy(icon: Icons.eco,                    color: Color(0xFF26A69A), name: 'Froggy',  cheer: "Leap forward! You've got this!"),
  Buddy(icon: Icons.star,                   color: Color(0xFFFFCA28), name: 'Simba',   cheer: "Roar! You're unstoppable!"),
  Buddy(icon: Icons.self_improvement,       color: Color(0xFF42A5F5), name: 'Pandy',   cheer: 'Balance is key. Great work!'),
  Buddy(icon: Icons.waves,                  color: Color(0xFF29B6F6), name: 'Flip',    cheer: "You're in the flow!"),
  Buddy(icon: Icons.auto_awesome,           color: Color(0xFFAB47BC), name: 'Flutter', cheer: 'Transformation in progress!'),
  Buddy(icon: Icons.hub,                    color: Color(0xFF26C6DA), name: 'Octo',    cheer: 'Multitasking champion!'),
  Buddy(icon: Icons.emoji_events,           color: Color(0xFFFFEE58), name: 'Star',    cheer: 'Shining bright today!'),
];

class BuddyWidget extends StatefulWidget {
  final Buddy buddy;
  final double size;
  final bool animate;

  const BuddyWidget({
    super.key,
    required this.buddy,
    this.size = 64,
    this.animate = false,
  });

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BuddyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotationAnim.value,
            child: child,
          ),
        );
      },
      child: Icon(
        widget.buddy.icon,
        color: widget.buddy.color,
        size: widget.size,
      ),
    );
  }
}
