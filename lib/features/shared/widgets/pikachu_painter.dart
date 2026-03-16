import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Accurate chibi Pikachu sitting on a Pokéball — cartoon outline style.
/// Features: proper pointed ears with black tips, round open eyes with specular,
/// W-shaped mouth, red cheeks, brown back-stripes, stubby feet, lightning tail,
/// and squish/bounce reaction on tap/fling.
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

  // ── colour palette ────────────────────────────────────────────────────────
  static const _kYellow      = Color(0xFFFFD700);
  static const _kYellowDark  = Color(0xFFE6B800);
  static const _kBrown       = Color(0xFF6B3A00);
  static const _kEarTip      = Color(0xFF1A1A2E);
  static const _kOutline     = Color(0xFF1A1200);
  static const _kRed         = Color(0xFFE53935);
  static const _kPokeRed     = Color(0xFFCC2200);
  static const _kWhite       = Color(0xFFF5F5F5);
  static const _kEyeBlack    = Color(0xFF1A1A2E);
  static const _kNose        = Color(0xFF5A2D00);

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
    final bob = math.sin(bobValue * 2 * math.pi) * 2.2;

    // Squish → stretch → settle
    double sX = 1.0, sY = 1.0;
    if (exciteValue > 0) {
      if (exciteValue < 0.35) {
        final t = exciteValue / 0.35;
        sX = 1 + t * 0.22;  sY = 1 - t * 0.18;
      } else if (exciteValue < 0.70) {
        final t = (exciteValue - 0.35) / 0.35;
        sX = 1.22 - t * 0.30;  sY = 0.82 + t * 0.36;
      } else {
        final t = (exciteValue - 0.70) / 0.30;
        sX = 0.92 + t * 0.08;  sY = 1.18 - t * 0.18;
      }
    }

    if (isFlipped) {
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // Orbit sparkle particles
    _drawParticles(canvas, cx, h * 0.48 + bob, w * 0.44, bobValue);

    // Pokéball first (body overlaps its top)
    final pokeY = h * 0.76 + bob * 0.35;
    final pokeR = w * 0.21;
    _drawPokeball(canvas, cx, pokeY, pokeR);

    final bodyY = h * 0.49 + bob;
    final r = w * 0.235;

    // ── Tail (behind body, right side) ───────────────────────────────────────
    _drawTail(canvas, cx + r * 0.85, bodyY + r * 0.3, r * 0.55);

    // ── Ears behind body ─────────────────────────────────────────────────────
    _drawEars(canvas, cx, bodyY, r);

    // ── Squish + lean transform for body group ────────────────────────────────
    canvas.save();
    canvas.translate(cx, bodyY);
    canvas.scale(sX, sY);
    if (leanAngle != 0) canvas.rotate(leanAngle);
    canvas.translate(-cx, -bodyY);

    // Back stripes (painted on body, behind face)
    _drawBackStripes(canvas, cx, bodyY, r);
    // Body
    _drawBody(canvas, cx, bodyY, r);
    // Arms
    _drawArms(canvas, cx, bodyY, r, exciteValue);
    // Feet
    _drawFeet(canvas, cx, bodyY, r);
    // Face
    _drawFace(canvas, cx, bodyY, r);

    canvas.restore();

    if (isFlipped) canvas.restore();
  }

  // ── Ears ──────────────────────────────────────────────────────────────────
  void _drawEars(Canvas canvas, double cx, double cy, double r) {
    _drawOneEar(canvas, cx - r * 0.68, cy - r * 0.95, -0.22, r);
    _drawOneEar(canvas, cx + r * 0.68, cy - r * 0.95,  0.22, r);
  }

  void _drawOneEar(Canvas canvas, double ex, double ey, double tilt, double r) {
    final eW = r * 0.44;
    final eH = r * 1.10;
    canvas.save();
    canvas.translate(ex, ey);
    canvas.rotate(tilt);

    // Yellow base
    final body = Path()
      ..moveTo(0, eH * 0.5)                   // bottom centre
      ..lineTo(-eW * 0.5, eH * 0.15)          // bottom-left
      ..quadraticBezierTo(-eW * 0.4, -eH * 0.05, 0, -eH * 0.5)  // left curve to tip
      ..quadraticBezierTo( eW * 0.4, -eH * 0.05, eW * 0.5, eH * 0.15)
      ..close();
    canvas.drawPath(body, _fill(_kYellow));

    // Black tip — top 32 %
    final cutY = -eH * 0.5 + eH * 0.32;
    final tipW = eW * 0.72;
    final tip = Path()
      ..moveTo(0, -eH * 0.5)
      ..quadraticBezierTo(-eW * 0.38, -eH * 0.20, -tipW / 2, cutY)
      ..lineTo( tipW / 2, cutY)
      ..quadraticBezierTo( eW * 0.38, -eH * 0.20, 0, -eH * 0.5)
      ..close();
    canvas.drawPath(tip, _fill(_kEarTip));

    canvas.drawPath(body, _stroke(_kOutline, 1.8));
    canvas.restore();
  }

  // ── Brown back stripes ────────────────────────────────────────────────────
  void _drawBackStripes(Canvas canvas, double cx, double cy, double r) {
    final p = Paint()
      ..color = _kBrown.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.17
      ..strokeCap = StrokeCap.round;

    // Two horizontal arcs on the right side of body (the "back")
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + r * 0.55, cy - r * 0.18),
          width: r * 0.70, height: r * 0.38),
      -0.6, 1.2, false, p,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + r * 0.55, cy + r * 0.22),
          width: r * 0.70, height: r * 0.38),
      -0.6, 1.2, false, p,
    );
  }

  // ── Body oval ─────────────────────────────────────────────────────────────
  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: r * 2.08, height: r * 2.24);
    canvas.drawOval(rect, _fill(_kYellow));
    // Belly highlight (lighter oval at top-centre)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy - r * 0.22), width: r * 1.12, height: r * 0.90),
      _fill(const Color(0xFFFFF176).withValues(alpha: 0.45)),
    );
    canvas.drawOval(rect, _stroke(_kOutline, 2.2));
  }

  // ── Arms ──────────────────────────────────────────────────────────────────
  void _drawArms(Canvas canvas, double cx, double cy, double r, double excite) {
    _drawOneArm(canvas, cx - r * 0.97, cy + r * 0.08, -0.50, r * 0.28);
    final rightAngle = excite > 0.3 ? 0.85 - excite * 0.65 : 0.45;
    _drawOneArm(canvas, cx + r * 0.97, cy,              rightAngle, r * 0.28);
  }

  void _drawOneArm(Canvas canvas, double ax, double ay, double angle, double len) {
    canvas.save();
    canvas.translate(ax, ay);
    canvas.rotate(angle);
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: len * 0.62, height: len),
      Radius.circular(len * 0.38),
    );
    canvas.drawRRect(rr, _fill(_kYellow));
    canvas.drawRRect(rr, _stroke(_kOutline, 1.8));
    canvas.restore();
  }

  // ── Feet ──────────────────────────────────────────────────────────────────
  void _drawFeet(Canvas canvas, double cx, double cy, double r) {
    for (final dx in [-0.32, 0.32]) {
      final fx = cx + r * dx;
      final fy = cy + r * 1.02;
      // Foot pad
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(fx, fy), width: r * 0.52, height: r * 0.28),
        _fill(_kYellowDark),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(fx, fy), width: r * 0.52, height: r * 0.28),
        _stroke(_kOutline, 1.6),
      );
      // Toe dots (3 small dots)
      for (final tdx in [-0.16, 0.0, 0.16]) {
        canvas.drawCircle(Offset(fx + r * tdx, fy + r * 0.08), r * 0.055,
            _fill(_kOutline));
      }
    }
  }

  // ── Face ──────────────────────────────────────────────────────────────────
  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    // Red cheeks (drawn behind eyes)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - r * 0.50, cy + r * 0.16),
          width: r * 0.44, height: r * 0.36),
      _fill(_kRed.withValues(alpha: 0.88)),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + r * 0.50, cy + r * 0.16),
          width: r * 0.44, height: r * 0.36),
      _fill(_kRed.withValues(alpha: 0.88)),
    );
    // Cheek sparkle
    canvas.drawCircle(
      Offset(cx - r * 0.45, cy + r * 0.09), r * 0.06,
      _fill(_kWhite.withValues(alpha: 0.70)),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.09), r * 0.06,
      _fill(_kWhite.withValues(alpha: 0.70)),
    );

    // Round open eyes
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * r * 0.29;
      final ey = cy - r * 0.08;
      // White sclera
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: r * 0.29, height: r * 0.32),
        _fill(_kWhite),
      );
      // Black iris/pupil
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey + r * 0.03), width: r * 0.22, height: r * 0.24),
        _fill(_kEyeBlack),
      );
      // Specular highlight
      canvas.drawCircle(
        Offset(ex + r * 0.05, ey - r * 0.06), r * 0.055,
        _fill(_kWhite),
      );
      // Outer eye line
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: r * 0.29, height: r * 0.32),
        _stroke(_kOutline, 1.4),
      );
    }

    // Tiny nose (brown oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.14), width: r * 0.14, height: r * 0.09),
      _fill(_kNose),
    );

    // W-shaped mouth
    final mY  = cy + r * 0.26;
    final mW  = r * 0.42;
    final mDip = r * 0.12;
    final mPath = Path()
      ..moveTo(cx - mW / 2, mY)
      ..quadraticBezierTo(cx - mW / 4, mY + mDip, cx, mY)
      ..quadraticBezierTo(cx + mW / 4, mY + mDip, cx + mW / 2, mY);
    canvas.drawPath(mPath, _stroke(_kOutline, 1.8));
  }

  // ── Lightning tail ────────────────────────────────────────────────────────
  void _drawTail(Canvas canvas, double tx, double ty, double len) {
    // Mini lightning bolt: two zigzag segments
    final p = Path()
      ..moveTo(tx, ty + len * 0.4)
      ..lineTo(tx + len * 0.25, ty)
      ..lineTo(tx + len * 0.05, ty)
      ..lineTo(tx + len * 0.30, ty - len * 0.42)
      ..lineTo(tx + len * 0.10, ty - len * 0.42)
      ..lineTo(tx + len * 0.38, ty - len * 0.86)
      ..lineTo(tx - len * 0.05, ty - len * 0.45)
      ..lineTo(tx + len * 0.15, ty - len * 0.45)
      ..lineTo(tx - len * 0.08, ty - len * 0.02)
      ..lineTo(tx + len * 0.10, ty - len * 0.02)
      ..close();
    canvas.drawPath(p, _fill(_kYellow));
    canvas.drawPath(p, _stroke(_kOutline, 1.4));
  }

  // ── Pokéball ──────────────────────────────────────────────────────────────
  void _drawPokeball(Canvas canvas, double cx, double cy, double r) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.90), width: r * 1.78, height: r * 0.24),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    final op = _stroke(_kOutline, 2.2);
    // Red top
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi, math.pi, true, _fill(_kPokeRed));
    // Highlight on red
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r * 0.20, cy - r * 0.32), radius: r * 0.28),
      math.pi * 1.1, math.pi * 0.55, false,
      Paint()..color = Colors.white.withValues(alpha: 0.25)
             ..style = PaintingStyle.stroke
             ..strokeWidth = r * 0.16
             ..strokeCap = StrokeCap.round,
    );
    // White bottom
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0, math.pi, true, _fill(_kWhite));
    // Ring
    canvas.drawCircle(Offset(cx, cy), r, op);
    // Band
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), op);
    // Button
    canvas.drawCircle(Offset(cx, cy), r * 0.22, _fill(_kWhite));
    canvas.drawCircle(Offset(cx, cy), r * 0.22, op);
    canvas.drawCircle(Offset(cx, cy), r * 0.09, _fill(const Color(0xFFBBBBBB)));
  }

  // ── Ambient orbit sparkles ────────────────────────────────────────────────
  static const _kPColors = [
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
    Color(0xFFFFEE58),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
  ];

  static const _kPCfg = [
    [0.00, 1.00, 4.5, 0, 0],
    [1.05, 0.82, 5.5, 1, 1],
    [2.09, 0.93, 4.5, 2, 2],
    [3.14, 0.75, 5.5, 3, 3],
    [4.19, 1.02, 3.5, 4, 2],
    [5.24, 0.78, 4.0, 5, 0],
  ];

  void _drawParticles(Canvas canvas, double cx, double cy, double orbitR, double t) {
    for (final cfg in _kPCfg) {
      final angle = (cfg[0] as double) + t * math.pi * 0.85;
      final pr    = orbitR * (cfg[1] as double);
      final px    = cx + math.cos(angle) * pr;
      final py    = cy + math.sin(angle) * pr * 0.50;
      final sz    = cfg[2] as double;
      final color = _kPColors[cfg[3] as int];
      _drawShape(canvas, px, py, sz, color, cfg[4] as int);
    }
  }

  void _drawShape(Canvas canvas, double x, double y, double sz, Color c, int type) {
    switch (type) {
      case 0:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: sz, height: sz),
            Radius.circular(sz * 0.3),
          ),
          _fill(c),
        );
      case 1:
        canvas.drawCircle(Offset(x, y), sz * 0.55,
            Paint()..color = c
                   ..style = PaintingStyle.stroke
                   ..strokeWidth = sz * 0.28);
      case 2:
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: sz * 1.4, height: sz * 0.36),
          _fill(c),
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: sz * 0.36, height: sz * 1.4),
          _fill(c),
        );
      case 3:
        _drawStar4(canvas, x, y, sz, c);
    }
  }

  void _drawStar4(Canvas canvas, double cx, double cy, double r, Color c) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final rad   = i.isEven ? r : r * 0.38;
      final p     = Offset(cx + math.cos(angle) * rad, cy + math.sin(angle) * rad);
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
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
