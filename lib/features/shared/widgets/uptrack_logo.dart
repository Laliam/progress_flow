import 'dart:math' as math;

import 'package:flutter/material.dart';

/// UpTrack brand logo.
///
/// Renders as an icon mark + optional wordmark.
///
/// ```dart
/// UpTrackLogo(size: 48)                     // icon only
/// UpTrackLogo(size: 48, showWordmark: true) // icon + "UpTrack"
/// ```
class UpTrackLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? color;

  const UpTrackLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? const Color(0xFF6366F1);

    if (!showWordmark) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _UpTrackIconPainter(color: logoColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _UpTrackIconPainter(color: logoColor),
          ),
        ),
        SizedBox(width: size * 0.18),
        _UpTrackWordmark(size: size, color: logoColor),
      ],
    );
  }
}

// ─── Icon mark ───────────────────────────────────────────────────────────────
//
//  Design: a rounded square tile with an upward-trending chart line
//  and an upward arrow at the tip — symbolising progress tracking.

class _UpTrackIconPainter extends CustomPainter {
  final Color color;
  _UpTrackIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.22; // corner radius

    // ── Background tile ───────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          Color.lerp(color, const Color(0xFF818CF8), 0.55)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final tilePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(r),
      ));
    canvas.drawPath(tilePath, bgPaint);

    // ── Inner glow ────────────────────────────────────────────────────────
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), w * 0.28, glowPaint);

    // ── Chart line (3 data points, upward trend) ──────────────────────────
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Points: bottom-left → mid → top-right
    final p1 = Offset(w * 0.18, h * 0.70);
    final p2 = Offset(w * 0.45, h * 0.50);
    final p3 = Offset(w * 0.68, h * 0.30);

    final chartPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);
    canvas.drawPath(chartPath, linePaint);

    // ── Data-point dots ───────────────────────────────────────────────────
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final dotR = w * 0.062;
    for (final pt in [p1, p2]) {
      canvas.drawCircle(pt, dotR, dotPaint);
    }

    // ── Arrow head at p3 ─────────────────────────────────────────────────
    final arrowAngle = math.atan2(p3.dy - p2.dy, p3.dx - p2.dx);
    final arrowLen = w * 0.20;
    final arrowSpread = 0.42; // radians

    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final a1 = Offset(
      p3.dx - arrowLen * math.cos(arrowAngle - arrowSpread),
      p3.dy - arrowLen * math.sin(arrowAngle - arrowSpread),
    );
    final a2 = Offset(
      p3.dx - arrowLen * math.cos(arrowAngle + arrowSpread),
      p3.dy - arrowLen * math.sin(arrowAngle + arrowSpread),
    );

    canvas.drawLine(p3, a1, arrowPaint);
    canvas.drawLine(p3, a2, arrowPaint);

    // ── Arrow dot (filled circle at tip) ─────────────────────────────────
    canvas.drawCircle(p3, dotR * 1.1, Paint()..color = Colors.white);

    // ── Baseline (horizontal) ─────────────────────────────────────────────
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.15, h * 0.79),
      Offset(w * 0.82, h * 0.79),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(_UpTrackIconPainter old) => old.color != color;
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────

class _UpTrackWordmark extends StatelessWidget {
  final double size;
  final Color color;

  const _UpTrackWordmark({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.56;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Up',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          TextSpan(
            text: 'Track',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen splash / hero logo for onboarding.
/// Shows the icon mark with animated pulse glow, plus the wordmark below.
class UpTrackHero extends StatefulWidget {
  final double iconSize;

  const UpTrackHero({super.key, this.iconSize = 80});

  @override
  State<UpTrackHero> createState() => _UpTrackHeroState();
}

class _UpTrackHeroState extends State<UpTrackHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.25, end: 0.60)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.iconSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            width: s * 1.35,
            height: s * 1.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: _glow.value),
                  blurRadius: s * 0.65,
                  spreadRadius: s * 0.05,
                ),
              ],
            ),
            child: child,
          ),
          child: Center(
            child: UpTrackLogo(size: s),
          ),
        ),
        SizedBox(height: s * 0.22),
        _UpTrackWordmark(size: s * 0.70, color: const Color(0xFF6366F1)),
      ],
    );
  }
}
