import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws a cartoon Pikachu sitting on a Pokéball.
/// [bobValue]  0..1 idle bob offset  (drives y position)
/// [walkValue] 0..1 leg swing cycle  (drives leg animation)
/// [isFlipped] mirror horizontally   (facing direction)
class PikachuPainter extends CustomPainter {
  final double bobValue;
  final double walkValue;
  final bool isFlipped;

  const PikachuPainter({
    required this.bobValue,
    required this.walkValue,
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Vertical bob offset (gentle idle bounce)
    final bob = math.sin(bobValue * 2 * math.pi) * 2.5;

    if (isFlipped) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    _drawPokeball(canvas, cx, cy + 16 + bob, size.width * 0.44);
    _drawBody(canvas, cx, cy - 4 + bob, size.width * 0.28);
    _drawLegs(canvas, cx, cy + 14 + bob, size.width * 0.26, walkValue);
    _drawArms(canvas, cx, cy - 2 + bob, size.width * 0.26);
    _drawTail(canvas, cx + size.width * 0.22, cy - 8 + bob);
    _drawHead(canvas, cx, cy - 22 + bob, size.width * 0.24);

    if (isFlipped) canvas.restore();
  }

  // ── Pokéball ────────────────────────────────────────────────────────────
  void _drawPokeball(Canvas canvas, double cx, double cy, double r) {
    final redPaint = Paint()..color = const Color(0xFFE53935);
    final whitePaint = Paint()..color = const Color(0xFFF5F5F5);
    final borderPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final centerFill = Paint()..color = const Color(0xFFF5F5F5);
    final centerBorder = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Red top half
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi, true, redPaint,
    );
    // White bottom half
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0, math.pi, true, whitePaint,
    );
    // Outer border
    canvas.drawCircle(Offset(cx, cy), r, borderPaint);
    // Horizontal stripe
    canvas.drawLine(
      Offset(cx - r, cy),
      Offset(cx + r, cy),
      borderPaint,
    );
    // Center button
    canvas.drawCircle(Offset(cx, cy), r * 0.22, centerFill);
    canvas.drawCircle(Offset(cx, cy), r * 0.22, centerBorder);
    // Inner button dot
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.10,
      Paint()..color = const Color(0xFFBDBDBD),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    final bodyPaint = Paint()..color = const Color(0xFFFFD600);
    final belly = Paint()..color = const Color(0xFFFFEE58);
    final outline = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Main body oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.8),
      bodyPaint,
    );
    // Lighter belly patch
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.3), width: r * 1.1, height: r * 1.0),
      belly,
    );
    // Body outline
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.8),
      outline,
    );
    // Brown back stripe markings
    final stripe = Paint()
      ..color = const Color(0xFF6D4C00)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.3, cy - r * 0.3),
          width: r * 0.6, height: r * 0.6),
      -math.pi / 2, math.pi / 2, false, stripe,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + r * 0.3, cy - r * 0.3),
          width: r * 0.6, height: r * 0.6),
      -math.pi / 2, math.pi / 2, false, stripe,
    );
  }

  // ── Legs (4 stubby) ───────────────────────────────────────────────────────
  void _drawLegs(
      Canvas canvas, double cx, double cy, double r, double walkV) {
    final legPaint = Paint()..color = const Color(0xFFFFD600);
    final outline = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final footPaint = Paint()..color = const Color(0xFFE65100);

    // Walk cycle: front legs swing opposite to back legs
    final swing = math.sin(walkV * 2 * math.pi) * 8;

    final legs = [
      // [x offset, y offset, swing multiplier]
      [-r * 0.55, r * 0.55, 1.0],  // front-left
      [r * 0.55, r * 0.55, -1.0],  // front-right
      [-r * 0.25, r * 0.7, -1.0],  // back-left
      [r * 0.25, r * 0.7, 1.0],   // back-right
    ];

    for (final leg in legs) {
      final lx = cx + leg[0];
      final ly = cy + leg[1];
      final angle = swing * leg[2] * (math.pi / 180);

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle);

      final legRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 8), width: 11, height: 16),
        const Radius.circular(6),
      );
      canvas.drawRRect(legRect, legPaint);
      canvas.drawRRect(legRect, outline);
      // Foot toe
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 17), width: 13, height: 7),
        footPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 17), width: 13, height: 7),
        outline,
      );

      canvas.restore();
    }
  }

  // ── Arms ──────────────────────────────────────────────────────────────────
  void _drawArms(Canvas canvas, double cx, double cy, double r) {
    final armPaint = Paint()..color = const Color(0xFFFFD600);
    final outline = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final side in [-1.0, 1.0]) {
      final ax = cx + side * r * 0.9;
      final ay = cy - r * 0.1;
      final angle = side * 0.35;

      canvas.save();
      canvas.translate(ax, ay);
      canvas.rotate(angle);
      final armRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 9, height: 16),
        const Radius.circular(5),
      );
      canvas.drawRRect(armRect, armPaint);
      canvas.drawRRect(armRect, outline);
      canvas.restore();
    }
  }

  // ── Tail (lightning bolt) ─────────────────────────────────────────────────
  void _drawTail(Canvas canvas, double tx, double ty) {
    final tailPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final darkTip = Paint()
      ..color = const Color(0xFF4A3000)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(tx, ty + 8)
      ..lineTo(tx + 6, ty)
      ..lineTo(tx + 2, ty - 5)
      ..lineTo(tx + 10, ty - 14)
      ..lineTo(tx + 5, ty - 14);

    canvas.drawPath(path, tailPaint);

    // Dark tip segment
    final tipPath = Path()
      ..moveTo(tx + 7, ty - 9)
      ..lineTo(tx + 10, ty - 14)
      ..lineTo(tx + 5, ty - 14);
    canvas.drawPath(tipPath, darkTip);
  }

  // ── Head ──────────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double cx, double cy, double r) {
    final headPaint = Paint()..color = const Color(0xFFFFD600);
    final outline = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Head circle
    canvas.drawCircle(Offset(cx, cy), r, headPaint);
    canvas.drawCircle(Offset(cx, cy), r, outline);

    // Ears
    _drawEar(canvas, cx - r * 0.62, cy - r * 0.85, -0.25);
    _drawEar(canvas, cx + r * 0.62, cy - r * 0.85, 0.25);

    // Red cheeks
    final cheekPaint = Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.55, cy + r * 0.2),
          width: r * 0.55, height: r * 0.38),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.55, cy + r * 0.2),
          width: r * 0.55, height: r * 0.38),
      cheekPaint,
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    final eyeShine = Paint()..color = Colors.white;
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * r * 0.32;
      final ey = cy - r * 0.08;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: r * 0.32, height: r * 0.38),
        eyePaint,
      );
      canvas.drawCircle(Offset(ex + r * 0.07, ey - r * 0.09), r * 0.07, eyeShine);
    }

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1),
          width: r * 0.7, height: r * 0.4),
      0.1, math.pi - 0.2, false, smilePaint,
    );

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1),
          width: r * 0.14, height: r * 0.10),
      Paint()..color = const Color(0xFF4A3000),
    );
  }

  void _drawEar(Canvas canvas, double ex, double ey, double angle) {
    final earPaint = Paint()..color = const Color(0xFFFFD600);
    final tipPaint = Paint()..color = const Color(0xFF1A1A1A);
    final outline = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.save();
    canvas.translate(ex, ey);
    canvas.rotate(angle);

    final earPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-7, -22)
      ..lineTo(7, -22)
      ..close();
    canvas.drawPath(earPath, earPaint);

    // Black tip
    final tipPath = Path()
      ..moveTo(-5, -16)
      ..lineTo(-7, -22)
      ..lineTo(7, -22)
      ..lineTo(5, -16)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    canvas.drawPath(earPath, outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PikachuPainter old) =>
      old.bobValue != bobValue ||
      old.walkValue != walkValue ||
      old.isFlipped != isFlipped;
}
