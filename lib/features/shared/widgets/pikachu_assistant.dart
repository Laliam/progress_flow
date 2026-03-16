import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const double _kSize = 64.0;
const double _kEdgePad = 14.0;
const double _kFriction = 0.96;
const double _kBounceDamping = 0.55;
const double _kMinVelocity = 0.3;

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum _SparkyState { idle, walking, dragged }

// ─────────────────────────────────────────────────────────────────────────────
// Reaction Particle
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionParticle {
  final String emoji;
  final Offset offset;
  final AnimationController controller;

  _ReactionParticle({
    required this.emoji,
    required this.offset,
    required this.controller,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PikachuAssistant widget
// Wraps a child in a Stack and overlays the animated "Sparky" character.
// ─────────────────────────────────────────────────────────────────────────────

class PikachuAssistant extends StatefulWidget {
  final Widget child;
  const PikachuAssistant({super.key, required this.child});

  @override
  State<PikachuAssistant> createState() => _PikachuAssistantState();
}

class _PikachuAssistantState extends State<PikachuAssistant>
    with TickerProviderStateMixin {
  // ── position & physics ──────────────────────────────────────────────────
  Offset _pos = const Offset(30, 500);
  Offset _velocity = Offset.zero;
  bool _facingRight = true;
  bool _initialized = false;

  // ── state ────────────────────────────────────────────────────────────────
  _SparkyState _state = _SparkyState.idle;
  Offset? _walkTarget;
  bool _isSleeping = false;

  // ── drag ────────────────────────────────────────────────────────────────
  Offset _dragOffset = Offset.zero;

  // ── animation controllers ─────────────────────────────────────────────
  late AnimationController _idleCtrl;  // gentle breathing bob
  late AnimationController _walkCtrl;  // walk cycle bob
  late AnimationController _reactCtrl; // tap scale bounce

  // ── reactions ────────────────────────────────────────────────────────────
  final List<_ReactionParticle> _reactions = [];

  late Ticker _ticker;

  // ── timers ───────────────────────────────────────────────────────────────
  Timer? _behaviorTimer;
  Timer? _sleepTimer;

  final _rand = Random();

  // ── screen size (cached in build) ───────────────────────────────────────
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..repeat();

    _reactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
      // Start near bottom-right corner
      _pos = Offset(
        size.width - _kSize - _kEdgePad - 20,
        size.height * 0.65,
      );
    }
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _walkCtrl.dispose();
    _reactCtrl.dispose();
    _ticker.dispose();
    _behaviorTimer?.cancel();
    _sleepTimer?.cancel();
    for (final r in _reactions) {
      r.controller.dispose();
    }
    super.dispose();
  }

  // ── Physics Tick ─────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (_state == _SparkyState.dragged || _screenSize == Size.zero) return;

    final maxX = _screenSize.width - _kSize - _kEdgePad;
    final maxY = _screenSize.height - _kSize - _kEdgePad;

    // Walking: move toward target at fixed speed
    if (_state == _SparkyState.walking && _walkTarget != null) {
      final diff = _walkTarget! - _pos;
      final dist = diff.distance;
      if (dist < 3.0) {
        setState(() {
          _state = _SparkyState.idle;
          _walkTarget = null;
          _velocity = Offset.zero;
        });
        _scheduleSleep();
      } else {
        const speed = 1.8;
        final dir = diff / dist;
        setState(() {
          _facingRight = dir.dx > 0;
          _pos = Offset(
            (_pos.dx + dir.dx * speed).clamp(_kEdgePad, maxX),
            (_pos.dy + dir.dy * speed).clamp(_kEdgePad, maxY),
          );
        });
      }
      return;
    }

    // Fling physics after a throw
    if (_velocity.distance < _kMinVelocity) {
      if (_velocity != Offset.zero) setState(() => _velocity = Offset.zero);
      return;
    }

    var newVel = _velocity * _kFriction;
    var newPos = _pos + newVel;

    // Edge bounce with haptic
    bool bounced = false;
    if (newPos.dx < _kEdgePad) {
      newPos = Offset(_kEdgePad, newPos.dy);
      newVel = Offset(-newVel.dx.abs() * _kBounceDamping, newVel.dy * 0.9);
      bounced = true;
    } else if (newPos.dx > maxX) {
      newPos = Offset(maxX, newPos.dy);
      newVel = Offset(-newVel.dx.abs() * _kBounceDamping, newVel.dy * 0.9);
      bounced = true;
    }
    if (newPos.dy < _kEdgePad) {
      newPos = Offset(newPos.dx, _kEdgePad);
      newVel = Offset(newVel.dx * 0.9, newVel.dy.abs() * _kBounceDamping);
      bounced = true;
    } else if (newPos.dy > maxY) {
      newPos = Offset(newPos.dx, maxY);
      newVel = Offset(newVel.dx * 0.85, -newVel.dy.abs() * _kBounceDamping);
      bounced = true;
    }
    if (bounced) HapticFeedback.lightImpact();

    setState(() {
      _pos = newPos;
      _velocity = newVel;
      _facingRight = newVel.dx >= 0;
    });
  }

  // ── Random Behavior ──────────────────────────────────────────────────────

  void _scheduleBehavior() {
    _behaviorTimer?.cancel();
    final delay = Duration(seconds: 10 + _rand.nextInt(15));
    _behaviorTimer = Timer(delay, () {
      if (mounted && _state == _SparkyState.idle) _startWalking();
      _scheduleBehavior();
    });
  }

  void _scheduleSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(const Duration(seconds: 40), () {
      if (mounted && _state == _SparkyState.idle) {
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
      _kEdgePad + _rand.nextDouble() * (maxY * 0.55) + maxY * 0.25,
    );
    setState(() {
      _state = _SparkyState.walking;
      _walkTarget = target;
      _isSleeping = false;
      _velocity = Offset.zero;
    });
    _sleepTimer?.cancel();
  }

  // ── Tap Handler ──────────────────────────────────────────────────────────

  void _onTap() {
    HapticFeedback.mediumImpact();
    setState(() => _isSleeping = false);
    _reactCtrl.forward(from: 0);
    _spawnReactions();
    _sleepTimer?.cancel();
    _scheduleSleep();
  }

  void _spawnReactions() {
    const emojis = ['⚡', '💛', '✨', '🌟', '💫', '❤️'];
    for (int i = 0; i < 5; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      final particle = _ReactionParticle(
        emoji: emojis[_rand.nextInt(emojis.length)],
        offset: Offset(
          (_rand.nextDouble() - 0.5) * 70,
          -10 - _rand.nextDouble() * 50,
        ),
        controller: ctrl,
      );
      setState(() => _reactions.add(particle));
      ctrl.forward().then((_) {
        if (mounted) {
          setState(() => _reactions.remove(particle));
          ctrl.dispose();
        }
      });
    }
  }

  // ── Drag Handlers ─────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    HapticFeedback.selectionClick();
    setState(() {
      _state = _SparkyState.dragged;
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
    final fling = d.velocity.pixelsPerSecond / 20.0;
    setState(() {
      _state = _SparkyState.idle;
      _velocity = fling;
    });
    _scheduleBehavior();
    _scheduleSleep();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: _pos.dx,
          top: _pos.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: _kSize,
              height: _kSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Reaction particles (overflow above)
                  for (final r in _reactions)
                    AnimatedBuilder(
                      animation: r.controller,
                      builder: (ctx, _) {
                        final t = r.controller.value;
                        return Positioned(
                          left: _kSize / 2 + r.offset.dx - 12,
                          top: r.offset.dy * t - 10,
                          child: Opacity(
                            opacity: (1 - t * 1.1).clamp(0, 1),
                            child: Text(
                              r.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),

                  // Sleep indicator
                  if (_isSleeping)
                    const Positioned(
                      right: -6,
                      top: -10,
                      child: Text('💤', style: TextStyle(fontSize: 14)),
                    ),

                  // Sparky sprite
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_idleCtrl, _walkCtrl, _reactCtrl]),
                    builder: (ctx, _) {
                      final idleBob =
                          _state != _SparkyState.dragged
                              ? sin(_idleCtrl.value * pi) * 3.0
                              : 0.0;
                      final walkBob =
                          _state == _SparkyState.walking
                              ? sin(_walkCtrl.value * 2 * pi) * 4.5
                              : 0.0;
                      final reactScale =
                          _reactCtrl.isAnimating
                              ? 1.0 + sin(_reactCtrl.value * pi) * 0.38
                              : 1.0;

                      return Transform.translate(
                        offset: Offset(0, -(idleBob + walkBob)),
                        child: Transform.scale(
                          scale: reactScale,
                          child: CustomPaint(
                            size: const Size(_kSize, _kSize),
                            painter: _SparkyPainter(
                              breathScale: _idleCtrl.value,
                              isDragged: _state == _SparkyState.dragged,
                              isSleeping: _isSleeping,
                              facingRight: _facingRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter — "Sparky" (Pikachu-inspired character, drawn in code)
// ─────────────────────────────────────────────────────────────────────────────

class _SparkyPainter extends CustomPainter {
  final double breathScale; // 0.0–1.0
  final bool isDragged;
  final bool isSleeping;
  final bool facingRight;

  const _SparkyPainter({
    required this.breathScale,
    required this.isDragged,
    required this.isSleeping,
    required this.facingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w / 2, h / 2);

    if (isDragged) {
      canvas.scale(1.20, 0.82); // squish on drag
    } else {
      final s = 1.0 + breathScale * 0.045;
      canvas.scale(s, s);
    }

    if (!facingRight) canvas.scale(-1, 1);
    canvas.translate(-w / 2, -h / 2);

    // ── Glow ──────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.62),
      25,
      Paint()
        ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ── Ears ──────────────────────────────────────────────────────────────
    final earPaint = Paint()..color = const Color(0xFFFFD600);
    final innerEarPaint =
        Paint()..color = const Color(0xFFFF8FAB).withValues(alpha: 0.88);

    // Left ear
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, h * 0.51)
        ..lineTo(w * 0.22, h * 0.04)
        ..lineTo(w * 0.40, h * 0.41)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.155, h * 0.47)
        ..lineTo(w * 0.23, h * 0.12)
        ..lineTo(w * 0.36, h * 0.40)
        ..close(),
      innerEarPaint,
    );

    // Right ear
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.60, h * 0.41)
        ..lineTo(w * 0.78, h * 0.04)
        ..lineTo(w * 0.90, h * 0.51)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, h * 0.40)
        ..lineTo(w * 0.77, h * 0.12)
        ..lineTo(w * 0.845, h * 0.47)
        ..close(),
      innerEarPaint,
    );

    // ── Head ──────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.62),
      w * 0.37,
      Paint()..color = const Color(0xFFFFD600),
    );

    // ── Cheeks (red) ──────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.25, h * 0.76), width: 16, height: 11),
      Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.80),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.75, h * 0.76), width: 16, height: 11),
      Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.80),
    );

    // ── Eyes ──────────────────────────────────────────────────────────────
    if (isSleeping) {
      final eyePaint = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.36, h * 0.60), width: 12, height: 8),
        0, pi, false, eyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.64, h * 0.60), width: 12, height: 8),
        0, pi, false, eyePaint,
      );
    } else {
      canvas.drawCircle(Offset(w * 0.36, h * 0.58), 5.0,
          Paint()..color = const Color(0xFF212121));
      canvas.drawCircle(Offset(w * 0.38, h * 0.56), 1.9,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.64, h * 0.58), 5.0,
          Paint()..color = const Color(0xFF212121));
      canvas.drawCircle(Offset(w * 0.66, h * 0.56), 1.9,
          Paint()..color = Colors.white);
    }

    // ── Nose ──────────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.665), width: 5, height: 3.5),
      Paint()..color = const Color(0xFF4E342E),
    );

    // ── Smile ─────────────────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.40, h * 0.73)
        ..quadraticBezierTo(w * 0.50, h * 0.81, w * 0.60, h * 0.73),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparkyPainter old) =>
      old.breathScale != breathScale ||
      old.isDragged != isDragged ||
      old.isSleeping != isSleeping ||
      old.facingRight != facingRight;
}
