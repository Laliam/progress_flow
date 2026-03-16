import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Chibi round Pikachu sitting on a Pokéball — outline cartoon style.
/// Matches the kawaii reference image with round blob body, spiky hair,
/// closed crescent eyes, red cheeks, stubby arms and floating orbit particles.
///
/// [bobValue]    0..1 drives idle sine wave
/// [exciteValue] 0..1 drives squish → bounce reaction (tap / fling)
/// [leanAngle]   radians — tilt body (-=left, +=right) while moving
/// [isFlipped]   mirror the entire canvas
class PikachuPainter extends CustomPainter {
  final double bobValue;
  final double exciteValue;
  final double leanAngle;
  final bool isFlipped;

  const PikachuPainter({
    required this.bobValue,
    this.exciteValue = 0.0,
    this.leanAngle = 0.0,
    this.isFlipped = false,
  });

  // ── colour constants ──────────────────────────────────────────────────────
  static const _kYellow  = Color(0xFFFFD600);
  static const _kOutline = Color(0xFF1A1200);
  static const _kRed     = Color(0xFFE53935);
  static const _kPokeRed = Color(0xFFD32F2F);
  static const _kWhite   = Color(0xFFF5F5F5);

  static Paint _fill(Color c) => Paint()..color = c;
  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Gentle idle bob
    final bob = math.sin(bobValue * 2 * math.pi) * 2.5;

    // Squish → stretch → settle for exciteValue
    double scaleX = 1.0, scaleY = 1.0;
    if (exciteValue > 0) {
      if (exciteValue < 0.35) {
        final t = exciteValue / 0.35;
        scaleX = 1 + t * 0.22;
        scaleY = 1 - t * 0.18;
      } else if (exciteValue < 0.70) {
        final t = (exciteValue - 0.35) / 0.35;
        scaleX = 1.22 - t * 0.30;
        scaleY = 0.82 + t * 0.36;
      } else {
        final t = (exciteValue - 0.70) / 0.30;
        scaleX = 0.92 + t * 0.08;
        scaleY = 1.18 - t * 0.18;
      }
    }

    if (isFlipped) {
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // Ambient floating particles (orbit based on bobValue)
    _drawParticles(canvas, cx, h * 0.48 + bob, w * 0.46, bobValue);

    // Pokéball drawn FIRST so body overlaps its top edge
    final pokeY = h * 0.72 + bob * 0.4;
    final pokeR = w * 0.26;
    _drawPokeball(canvas, cx, pokeY, pokeR);

    // Squish + lean transform for body group
    final bodyY = h * 0.40 + bob;
    canvas.save();
    canvas.translate(cx, bodyY);
    canvas.scale(scaleX, scaleY);
    if (leanAngle != 0) canvas.rotate(leanAngle);
    canvas.translate(-cx, -bodyY);

    final r = w * 0.28;

    // Draw hair spikes → body fill → body outline (fill covers spike bases)
    _drawHair(canvas, cx, bodyY, r);
    _drawBodyFill(canvas, cx, bodyY, r);
    _drawBodyOutline(canvas, cx, bodyY, r);

    // Stubby arms
    _drawArms(canvas, cx, bodyY, r, exciteValue);

    // Face features
    _drawFace(canvas, cx, bodyY + r * 0.08, r);

    canvas.restore();

    if (isFlipped) canvas.restore();
  }

  // ── Hair / spikes ─────────────────────────────────────────────────────────
  void _drawHair(Canvas canvas, double cx, double cy, double r) {
    // 5 spikes whose bases are inside the body oval so body fill hides bases.
    // Only the tips protrude above the top of the oval.
    final tips = [
      Offset(cx - r * 0.55, cy - r * 1.38),
      Offset(cx - r * 0.23, cy - r * 1.54),
      Offset(cx + r * 0.05, cy - r * 1.58),
      Offset(cx + r * 0.30, cy - r * 1.48),
      Offset(cx + r * 0.58, cy - r * 1.27),
    ];
    final bases = [
      Offset(cx - r * 0.52, cy - r * 0.62),
      Offset(cx - r * 0.21, cy - r * 0.70),
      Offset(cx + r * 0.05, cy - r * 0.72),
      Offset(cx + r * 0.29, cy - r * 0.68),
      Offset(cx + r * 0.55, cy - r * 0.58),
    ];
    final hw = [r * 0.14, r * 0.16, r * 0.17, r * 0.16, r * 0.14];

    for (int i = 0; i < tips.length; i++) {
      final t = tips[i];
      final b = bases[i];
      final h = hw[i];
      final perp = Offset(-(b.dy - t.dy), b.dx - t.dx);
      final len = perp.distance;
      final pNorm = perp / len;

      final path = Path()
        ..moveTo(t.dx, t.dy)
        ..lineTo(b.dx - pNorm.dx * h, b.dy - pNorm.dy * h)
        ..lineTo(b.dx + pNorm.dx * h, b.dy + pNorm.dy * h)
        ..close();

      canvas.drawPath(path, _fill(_kYellow));
      // Outline: only the two outer edges (base edge is hidden under body fill)
      final o = _stroke(_kOutline, 2.2);
      canvas.drawLine(t, Offset(b.dx - pNorm.dx * h, b.dy - pNorm.dy * h), o);
      canvas.drawLine(t, Offset(b.dx + pNorm.dx * h, b.dy + pNorm.dy * h), o);
    }
  }

  // ── Body oval ─────────────────────────────────────────────────────────────
  void _drawBodyFill(Canvas canvas, double cx, double cy, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2.1, height: r * 2.3),
      _fill(_kYellow),
    );
  }

  void _drawBodyOutline(Canvas canvas, double cx, double cy, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2.1, height: r * 2.3),
      _stroke(_kOutline, 2.5),
    );
  }

  // ── Arms ──────────────────────────────────────────────────────────────────
  void _drawArms(
      Canvas canvas, double cx, double cy, double r, double excite) {
    _drawArm(canvas, cx - r * 1.00, cy + r * 0.10, -0.55, r * 0.30);
    // Right arm raises when excited
    final rightAngle = excite > 0.3 ? 0.9 - excite * 0.7 : 0.50;
    _drawArm(canvas, cx + r * 1.00, cy - r * 0.02, rightAngle, r * 0.30);
  }

  void _drawArm(Canvas canvas, double ax, double ay, double angle, double len) {
    canvas.save();
    canvas.translate(ax, ay);
    canvas.rotate(angle);
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 0), width: len * 0.65, height: len),
      Radius.circular(len * 0.4),
    );
    canvas.drawRRect(rr, _fill(_kYellow));
    canvas.drawRRect(rr, _stroke(_kOutline, 2.0));
    canvas.restore();
  }

  // ── Face ──────────────────────────────────────────────────────────────────
  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    // Red cheeks
    canvas.drawCircle(
        Offset(cx - r * 0.46, cy + r * 0.18), r * 0.20,
        _fill(_kRed.withValues(alpha: 0.85)));
    canvas.drawCircle(
        Offset(cx + r * 0.46, cy + r * 0.18), r * 0.20,
        _fill(_kRed.withValues(alpha: 0.85)));

    // Closed crescent eyes (arcs)
    final eyeP = _stroke(_kOutline, 1.9);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - r * 0.28, cy - r * 0.05),
          width: r * 0.32,
          height: r * 0.22),
      math.pi, math.pi, false, eyeP,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + r * 0.28, cy - r * 0.05),
          width: r * 0.32,
          height: r * 0.22),
      math.pi, math.pi, false, eyeP,
    );

    // Small beak/smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.25),
          width: r * 0.26,
          height: r * 0.16),
      0.2, math.pi - 0.4, false, _stroke(_kOutline, 1.6),
    );
  }

  // ── Pokéball ──────────────────────────────────────────────────────────────
  void _drawPokeball(Canvas canvas, double cx, double cy, double r) {
    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.88), width: r * 1.8, height: r * 0.28),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    final op = _stroke(_kOutline, 2.5);
    // Red top half
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi, math.pi, true, _fill(_kPokeRed));
    // White bottom half
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0, math.pi, true, _fill(_kWhite));
    // Outer ring
    canvas.drawCircle(Offset(cx, cy), r, op);
    // Horizontal stripe
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), op);
    // Center button
    canvas.drawCircle(Offset(cx, cy), r * 0.22, _fill(_kWhite));
    canvas.drawCircle(Offset(cx, cy), r * 0.22, op);
    // Inner dot
    canvas.drawCircle(Offset(cx, cy), r * 0.10, _fill(const Color(0xFFBDBDBD)));
  }

  // ── Ambient orbit particles ───────────────────────────────────────────────
  static const _kPColors = [
    Color(0xFF42A5F5), // blue
    Color(0xFFFF7043), // orange
    Color(0xFF26C6DA), // cyan
    Color(0xFFFFEE58), // yellow
    Color(0xFF26A69A), // teal
    Color(0xFFEF5350), // red
  ];

  // [angle_offset, orbit_r_factor, size, color_idx, shape(0=sq,1=ring,2=plus,3=star)]
  static const _kPCfg = [
    [0.00, 1.00, 4.5, 0, 0],
    [1.05, 0.82, 5.5, 1, 1],
    [2.09, 0.93, 4.5, 2, 2],
    [3.14, 0.75, 5.5, 3, 3],
    [4.19, 1.02, 3.5, 4, 2],
    [5.24, 0.78, 4.0, 5, 0],
  ];

  void _drawParticles(
      Canvas canvas, double cx, double cy, double orbitR, double t) {
    for (final cfg in _kPCfg) {
      final angle = (cfg[0] as double) + t * math.pi * 0.9;
      final r = orbitR * (cfg[1] as double);
      final px = cx + math.cos(angle) * r;
      final py = cy + math.sin(angle) * r * 0.55;
      final sz = cfg[2] as double;
      final color = _kPColors[cfg[3] as int];
      _drawShape(canvas, px, py, sz, color, cfg[4] as int);
    }
  }

  void _drawShape(
      Canvas canvas, double x, double y, double sz, Color c, int type) {
    switch (type) {
      case 0: // rounded square
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: sz, height: sz),
            Radius.circular(sz * 0.3),
          ),
          _fill(c),
        );
      case 1: // hollow ring
        canvas.drawCircle(Offset(x, y), sz * 0.55,
            Paint()
              ..color = c
              ..style = PaintingStyle.stroke
              ..strokeWidth = sz * 0.30);
      case 2: // plus sign
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: sz * 1.4, height: sz * 0.36),
          _fill(c),
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: sz * 0.36, height: sz * 1.4),
          _fill(c),
        );
      case 3: // 4-point star
        _drawStar4(canvas, x, y, sz, c);
    }
  }

  void _drawStar4(Canvas canvas, double cx, double cy, double r, Color c) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final rad = i.isEven ? r : r * 0.38;
      final p = Offset(cx + math.cos(angle) * rad, cy + math.sin(angle) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, _fill(c));
  }

  @override
  bool shouldRepaint(PikachuPainter old) =>
      old.bobValue != bobValue ||
      old.exciteValue != exciteValue ||
      old.leanAngle != leanAngle ||
      old.isFlipped != isFlipped;
}
