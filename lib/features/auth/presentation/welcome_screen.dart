import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_service.dart';
import '../application/auth_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../shared/widgets/uptrack_logo.dart';

// ─── Welcome Screen ───────────────────────────────────────────────────────────

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _isSigningIn = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final didSignIn = await ref.read(authServiceProvider).signInWithGoogle();
      if (!didSignIn) return;
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final profile =
            await ref.read(profileRepositoryProvider).fetchProfile(userId);
        if (!mounted) return;
        if (profile == null || profile.username.isEmpty) {
          context.go('/profile', extra: {'setup': true});
          return;
        }
      }
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Animated gradient orbs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) {
              final t = _bgCtrl.value;
              return CustomPaint(
                size: size,
                painter: _OrbPainter(t),
              );
            },
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // Logo + wordmark
                      const UpTrackLogo(
                          size: 52, showWordmark: true),
                      const Spacer(flex: 2),
                      _HeroText(),
                      const SizedBox(height: 12),
                      _FeatureRow(),
                      const Spacer(flex: 3),
                      _PrimaryButton(
                        label: 'Sign In',
                        icon: Icons.login_rounded,
                        onTap: () => context.push('/auth/signin'),
                      ),
                      const SizedBox(height: 12),
                      _SecondaryButton(
                        label: 'Create Account',
                        icon: Icons.person_add_outlined,
                        onTap: () => context.push('/auth/signup'),
                      ),
                      const SizedBox(height: 16),
                      _OrDivider(),
                      const SizedBox(height: 16),
                      _GoogleButton(
                        isLoading: _isSigningIn,
                        onTap: _signInWithGoogle,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'By continuing, you agree to stay kind to your future self.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.38),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Orb background painter ──────────────────────────────────────────────────

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void drawOrb(
        Offset center, double radius, Color color1, Color color2) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color1, color2]).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      canvas.drawCircle(center, radius, paint);
    }

    final s1 = math.sin(t * math.pi);
    final c1 = math.cos(t * math.pi);

    drawOrb(
      Offset(size.width * 0.15 + s1 * 40, size.height * 0.18 + c1 * 30),
      size.width * 0.55,
      const Color(0xFF3B2FA0).withValues(alpha: 0.55),
      Colors.transparent,
    );
    drawOrb(
      Offset(size.width * 0.82 - c1 * 30, size.height * 0.55 + s1 * 40),
      size.width * 0.48,
      const Color(0xFF0C4A6E).withValues(alpha: 0.50),
      Colors.transparent,
    );
    drawOrb(
      Offset(size.width * 0.35 + s1 * 20, size.height * 0.85 - c1 * 25),
      size.width * 0.40,
      const Color(0xFF064E3B).withValues(alpha: 0.45),
      Colors.transparent,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE0E7FF), Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Track progress.\nTogether.',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Smart daily targets, gentle nudges, and collaborative\nchallenges that keep your goals flowing forward.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.60),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.auto_graph_rounded, 'Smart targets', Color(0xFF6366F1)),
      (Icons.groups_rounded, 'Race mode', Color(0xFFF43F5E)),
      (Icons.notifications_active_rounded, 'Daily nudges', Color(0xFF10B981)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: f.$3.withValues(alpha: 0.14),
            border: Border.all(color: f.$3.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 14, color: f.$3),
              const SizedBox(width: 6),
              Text(
                f.$2,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black54,
                  ),
                )
              else
                _GoogleLogo(),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Signing in...' : 'Continue with Google',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal four-color Google "G" logo.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final colors = {
      'blue': const Color(0xFF4285F4),
      'red': const Color(0xFFEA4335),
      'yellow': const Color(0xFFFBBC05),
      'green': const Color(0xFF34A853),
    };

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.36
      ..strokeCap = StrokeCap.butt;

    // Draw arc segments: red top-right, yellow bottom, green left, blue top-left
    final segments = [
      ('red', -15.0, 90.0),
      ('yellow', 75.0, 90.0),
      ('green', 165.0, 90.0),
      ('blue', 255.0, 90.0),
    ];

    for (final seg in segments) {
      strokePaint.color = colors[seg.$1]!;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.64),
        _deg(seg.$2),
        _deg(seg.$3),
        false,
        strokePaint,
      );
    }

    // White cutout center + right bar
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.36, paint);

    // Blue right bar
    paint.color = colors['blue']!;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.95, r * 0.27),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, paint);

    // White gap between circle and bar
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(cx - r * 0.05, cy - r * 0.135, r * 0.1, r * 0.27),
      paint,
    );
  }

  double _deg(double d) => d * math.pi / 180;

  @override
  bool shouldRepaint(_GoogleLogoPainter _) => false;
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
