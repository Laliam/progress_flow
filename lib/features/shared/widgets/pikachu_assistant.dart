import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'emoji_text.dart';
import 'pikachu_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const double _kSize = 80.0;
const double _kEdgePad = 12.0;
const double _kFriction = 0.96;
const double _kBounceDamping = 0.52;
const double _kMinVelocity = 0.4;

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum _PikState { idle, walking, dragged }

// ─────────────────────────────────────────────────────────────────────────────
// Reaction Particle
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final String emoji;
  final Offset startOffset;
  final AnimationController ctrl;

  _Particle({
    required this.emoji,
    required this.startOffset,
    required this.ctrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PikachuAssistant
// Wraps child in a Stack and floats the animated Pikachu character on top.
// ─────────────────────────────────────────────────────────────────────────────

class PikachuAssistant extends StatefulWidget {
  final Widget child;
  const PikachuAssistant({super.key, required this.child});

  @override
  State<PikachuAssistant> createState() => _PikachuAssistantState();
}

class _PikachuAssistantState extends State<PikachuAssistant>
    with TickerProviderStateMixin {
  // ── position & physics ───────────────────────────────────────────────────
  Offset _pos = const Offset(30, 500);
  Offset _velocity = Offset.zero;
  bool _facingRight = true;
  bool _initialized = false;

  // ── state ────────────────────────────────────────────────────────────────
  _PikState _state = _PikState.idle;
  Offset? _walkTarget;
  bool _isSleeping = false;

  // ── drag ─────────────────────────────────────────────────────────────────
  Offset _dragOffset = Offset.zero;

  // ── animation controllers ─────────────────────────────────────────────────
  late AnimationController _bobCtrl;     // idle bob (loop)
  late AnimationController _exciteCtrl;  // squish/bounce on tap or fling (one-shot)

  double _leanAngle = 0.0;

  // ── reaction particles ───────────────────────────────────────────────────
  final List<_Particle> _particles = [];

  // ── physics ticker ───────────────────────────────────────────────────────
  late Ticker _ticker;

  // ── timers ───────────────────────────────────────────────────────────────
  Timer? _behaviorTimer;
  Timer? _sleepTimer;

  final _rand = Random();
  Size _screenSize = Size.zero;

  // ── reaction emojis ──────────────────────────────────────────────────────
  static const _kReactions = ['⚡', '💛', '✨', '🌟', '💫', '💖', '🎉'];

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _exciteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _ticker = createTicker(_onTick)..start();
    _scheduleBehavior();
    _scheduleSleep();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final size = MediaQuery.of(context).size;
      _pos = Offset(
        size.width - _kSize - _kEdgePad - 16,
        size.height * 0.65,
      );
    }
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    _exciteCtrl.dispose();
    _ticker.dispose();
    _behaviorTimer?.cancel();
    _sleepTimer?.cancel();
    for (final p in _particles) {
      p.ctrl.dispose();
    }
    super.dispose();
  }

  // ── Physics tick ─────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (_state == _PikState.dragged || _screenSize == Size.zero) return;

    final maxX = _screenSize.width - _kSize - _kEdgePad;
    final maxY = _screenSize.height - _kSize - _kEdgePad;

    if (_state == _PikState.walking && _walkTarget != null) {
      final diff = _walkTarget! - _pos;
      final dist = diff.distance;
      if (dist < 3.0) {
        setState(() {
          _state = _PikState.idle;
          _walkTarget = null;
          _velocity = Offset.zero;
        });
        _scheduleSleep();
      } else {
        const speed = 1.6;
        final dir = diff / dist;
        final newLean = (dir.dx * 0.22).clamp(-0.28, 0.28);
        setState(() {
          _facingRight = dir.dx > 0;
          _leanAngle = newLean;
          _pos = Offset(
            (_pos.dx + dir.dx * speed).clamp(_kEdgePad, maxX),
            (_pos.dy + dir.dy * speed).clamp(_kEdgePad, maxY),
          );
        });
      }
      return;
    }

    if (_velocity.distance < _kMinVelocity) {
      if (_velocity != Offset.zero) {
        setState(() {
          _velocity = Offset.zero;
          _leanAngle = 0.0;
        });
        // Landing bounce
        _exciteCtrl.forward(from: 0);
      }
      return;
    }

    var vel = _velocity * _kFriction;
    var pos = _pos + vel;
    bool bounced = false;

    if (pos.dx < _kEdgePad) {
      pos = Offset(_kEdgePad, pos.dy);
      vel = Offset(vel.dx.abs() * _kBounceDamping, vel.dy * 0.88);
      bounced = true;
    } else if (pos.dx > maxX) {
      pos = Offset(maxX, pos.dy);
      vel = Offset(-vel.dx.abs() * _kBounceDamping, vel.dy * 0.88);
      bounced = true;
    }
    if (pos.dy < _kEdgePad) {
      pos = Offset(pos.dx, _kEdgePad);
      vel = Offset(vel.dx * 0.88, vel.dy.abs() * _kBounceDamping);
      bounced = true;
    } else if (pos.dy > maxY) {
      pos = Offset(pos.dx, maxY);
      vel = Offset(vel.dx * 0.88, -vel.dy.abs() * _kBounceDamping);
      bounced = true;
    }
    if (bounced) HapticFeedback.lightImpact();

    setState(() {
      _pos = pos;
      _velocity = vel;
      _facingRight = vel.dx >= 0;
      _leanAngle = (vel.dx * 0.018).clamp(-0.28, 0.28);
    });
  }

  // ── Behavior scheduler ────────────────────────────────────────────────────

  void _scheduleBehavior() {
    _behaviorTimer?.cancel();
    _behaviorTimer = Timer(
      Duration(seconds: 10 + _rand.nextInt(16)),
      () {
        if (mounted && _state == _PikState.idle) _startWalking();
        _scheduleBehavior();
      },
    );
  }

  void _scheduleSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(const Duration(seconds: 38), () {
      if (mounted && _state == _PikState.idle) {
        setState(() => _isSleeping = true);
      }
    });
  }

  void _startWalking() {
    if (_screenSize == Size.zero) return;
    final maxX = _screenSize.width - _kSize - _kEdgePad;
    final maxY = _screenSize.height - _kSize - _kEdgePad;
    final target = Offset(
      _kEdgePad + _rand.nextDouble() * (maxX - _kEdgePad),
      _kEdgePad + _rand.nextDouble() * (maxY * 0.5) + maxY * 0.2,
    );
    setState(() {
      _state = _PikState.walking;
      _walkTarget = target;
      _isSleeping = false;
      _velocity = Offset.zero;
      _leanAngle = 0.0;
    });
    _sleepTimer?.cancel();
  }

  // ── Tap ───────────────────────────────────────────────────────────────────

  void _onTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isSleeping = false);
    _exciteCtrl.forward(from: 0);
    _spawnParticles();
    _sleepTimer?.cancel();
    _scheduleSleep();
  }

  void _spawnParticles() {
    for (int i = 0; i < 5; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      final particle = _Particle(
        emoji: _kReactions[_rand.nextInt(_kReactions.length)],
        startOffset: Offset(
          (_rand.nextDouble() - 0.5) * 70,
          -_rand.nextDouble() * 55 - 10,
        ),
        ctrl: ctrl,
      );
      setState(() => _particles.add(particle));
      ctrl.forward().then((_) {
        if (mounted) setState(() => _particles.remove(particle));
        ctrl.dispose();
      });
    }
  }

  // ── Drag ─────────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    HapticFeedback.selectionClick();
    setState(() {
      _state = _PikState.dragged;
      _isSleeping = false;
      _velocity = Offset.zero;
      _dragOffset = d.globalPosition - _pos;
    });
    _behaviorTimer?.cancel();
    _sleepTimer?.cancel();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _pos = d.globalPosition - _dragOffset;
      _facingRight = d.delta.dx >= 0;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final fling = d.velocity.pixelsPerSecond / 18.0;
    setState(() {
      _state = _PikState.idle;
      _velocity = fling;
    });
    _scheduleBehavior();
    _scheduleSleep();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        // ── Pikachu overlay ────────────────────────────────────────────────
        Positioned(
          left: _pos.dx,
          top: _pos.dy,
          width: _kSize,
          height: _kSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Reaction particles
                for (final p in _particles)
                  AnimatedBuilder(
                    animation: p.ctrl,
                    builder: (context, child) {
                      final t = p.ctrl.value;
                      return Positioned(
                        left: _kSize / 2 + p.startOffset.dx - 12,
                        top: p.startOffset.dy * t,
                        child: Opacity(
                          opacity: (1 - t * 1.1).clamp(0.0, 1.0),
                          child: Text(p.emoji, style: emojiStyle(fontSize: 20)),
                        ),
                      );
                    },
                  ),

                // Sleep indicator
                if (_isSleeping)
                  Positioned(
                    right: -4,
                    top: -12,
                    child: Text('💤', style: emojiStyle(fontSize: 14)),
                  ),

                // Pikachu custom painter
                AnimatedBuilder(
                  animation: Listenable.merge([_bobCtrl, _exciteCtrl]),
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(_kSize, _kSize),
                      painter: PikachuPainter(
                        bobValue: _bobCtrl.value,
                        exciteValue: _exciteCtrl.value,
                        leanAngle: _leanAngle,
                        isFlipped: !_facingRight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
