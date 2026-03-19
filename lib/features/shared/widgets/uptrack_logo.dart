import 'package:flutter/material.dart';

/// UpTrack brand logo.
///
/// Renders the UpTrack image logo with optional wordmark.
///
/// ```dart
/// UpTrackLogo(size: 48)                     // icon only
/// UpTrackLogo(size: 48, showWordmark: true) // icon + "UpTrack"
/// ```
class UpTrackLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  const UpTrackLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.jpeg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!showWordmark) return logoWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        SizedBox(width: size * 0.18),
        _UpTrackWordmark(size: size, color: wordmarkColor),
      ],
    );
  }
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────

class _UpTrackWordmark extends StatelessWidget {
  final double size;
  final Color? color;

  const _UpTrackWordmark({required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.56;
    final baseColor = color ?? const Color(0xFFFF6B2B);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Up',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: baseColor,
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
    _glow = Tween<double>(begin: 0.20, end: 0.55)
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
            width: s * 1.30,
            height: s * 1.30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B2B).withValues(alpha: _glow.value),
                  blurRadius: s * 0.65,
                  spreadRadius: s * 0.05,
                ),
              ],
            ),
            child: child,
          ),
          child: Center(child: UpTrackLogo(size: s)),
        ),
        SizedBox(height: s * 0.22),
        _UpTrackWordmark(size: s * 0.70),
      ],
    );
  }
}


/// UpTrack brand logo.
///
/// Renders as an icon mark + optional wordmark.
///
/// ```dart
/// UpTrackLogo(size: 48)                     // icon only
/// UpTrackLogo(size: 48, showWordmark: true) // icon + "UpTrack"
