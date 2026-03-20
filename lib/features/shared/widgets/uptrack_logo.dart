import 'package:flutter/material.dart';

/// UpTrack brand logo.
///
/// - [UpTrackLogo] — square icon mark (uptrack_icon.jpeg), rounded corners
/// - [UpTrackWordmark] — full horizontal wordmark (uptrack_logo.jpeg)
/// - [UpTrackBrand] — icon + text inline for nav bars / headers
/// - [UpTrackHero] — pulsing-glow hero for welcome/splash screens

class UpTrackLogo extends StatelessWidget {
  final double size;
  const UpTrackLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/uptrack_icon.jpeg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Full horizontal wordmark (dark charcoal bg, orange "Up" + white "Track").
class UpTrackWordmark extends StatelessWidget {
  final double height;
  const UpTrackWordmark({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/uptrack_logo.jpeg',
      height: height,
      width: height * (2560 / 1440),
      fit: BoxFit.cover,
    );
  }
}

/// Compact inline brand: icon + "UpTrack" text (for headers/nav).
class UpTrackBrand extends StatelessWidget {
  final double iconSize;
  const UpTrackBrand({super.key, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UpTrackLogo(size: iconSize),
        SizedBox(width: iconSize * 0.20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Up',
                style: TextStyle(
                  fontSize: iconSize * 0.56,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF6B2B),
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'Track',
                style: TextStyle(
                  fontSize: iconSize * 0.56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen hero for onboarding — pulsing orange glow + wordmark below.
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
        SizedBox(height: s * 0.28),
        UpTrackWordmark(height: s * 0.55),
      ],
    );
  }
}
