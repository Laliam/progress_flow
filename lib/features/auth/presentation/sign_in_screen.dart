import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_service.dart';
import '../application/auth_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../shared/widgets/responsive_layout.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
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
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) => CustomPaint(
              size: size,
              painter: _BgPainter(_bgCtrl.value),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          _GlassBack(),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/auth/signup'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isTablet(context) ? 56 : 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),

                              // Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_open_rounded,
                                  color: Color(0xFF818CF8),
                                  size: 26,
                                ),
                              ),

                              const SizedBox(height: 20),

                              ShaderMask(
                                shaderCallback: (b) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFE0E7FF),
                                    Color(0xFF818CF8),
                                  ],
                                ).createShader(b),
                                child: const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Sign in to pick up where you left off.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 36),

                              // Email field
                              _Field(
                                controller: _emailCtrl,
                                label: 'Email address',
                                hint: 'you@example.com',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              _Field(
                                controller: _passwordCtrl,
                                label: 'Password',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscure: _obscurePass,
                                onToggleObscure: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                textInputAction: TextInputAction.done,
                                onSubmit: _signIn,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              // Sign in button
                              _BigButton(
                                label: 'Sign In',
                                isLoading: _isLoading,
                                onTap: _signIn,
                              ),

                              const SizedBox(height: 24),

                              Center(
                                child: GestureDetector(
                                  onTap: () => context.push('/auth/signup'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.50),
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Create one',
                                          style: TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return AuthPageWrapper(child: scaffold);
  }
}

// ─── Sign Up Screen ───────────────────────────────────────────────────────────

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.go('/profile', extra: {'setup': true});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) => CustomPaint(
              size: size,
              painter: _BgPainter(_bgCtrl.value, reversed: true),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          _GlassBack(),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/auth/signin'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isTablet(context) ? 56 : 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),

                              // Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Color(0xFF34D399),
                                  size: 26,
                                ),
                              ),

                              const SizedBox(height: 20),

                              ShaderMask(
                                shaderCallback: (b) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFD1FAE5),
                                    Color(0xFF34D399),
                                  ],
                                ).createShader(b),
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Join and start tracking your goals today.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 36),

                              _Field(
                                controller: _emailCtrl,
                                label: 'Email address',
                                hint: 'you@example.com',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              _Field(
                                controller: _passwordCtrl,
                                label: 'Password',
                                hint: 'Min. 6 characters',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscure: _obscurePass,
                                onToggleObscure: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'At least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              _Field(
                                controller: _confirmCtrl,
                                label: 'Confirm password',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscure: _obscureConfirm,
                                onToggleObscure: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                textInputAction: TextInputAction.done,
                                onSubmit: _signUp,
                                validator: (v) {
                                  if (v != _passwordCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              _BigButton(
                                label: 'Create Account',
                                isLoading: _isLoading,
                                onTap: _signUp,
                                color: const Color(0xFF10B981),
                                glowColor: const Color(0xFF10B981),
                              ),

                              const SizedBox(height: 16),

                              Center(
                                child: Text(
                                  'By signing up, you agree to stay kind to your future self.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.35),
                                    height: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Center(
                                child: GestureDetector(
                                  onTap: () => context.push('/auth/signin'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.50),
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF34D399),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return AuthPageWrapper(child: scaffold);
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────

class _GlassBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go('/welcome'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: Colors.white),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmit;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.onToggleObscure,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.50), fontSize: 14),
        prefixIcon: Icon(prefixIcon,
            size: 20, color: Colors.white.withValues(alpha: 0.40)),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final Color color;
  final Color glowColor;

  const _BigButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.color = const Color(0xFF6366F1),
    this.glowColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background painter ───────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  final double t;
  final bool reversed;
  _BgPainter(this.t, {this.reversed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.sin(t * math.pi);
    final c = math.cos(t * math.pi);
    final flip = reversed ? -1.0 : 1.0;

    void orb(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    orb(
      Offset(size.width * (reversed ? 0.85 : 0.15) + s * 50 * flip,
          size.height * 0.20 + c * 40),
      size.width * 0.55,
      const Color(0xFF3B2FA0).withValues(alpha: 0.50),
    );
    orb(
      Offset(size.width * (reversed ? 0.15 : 0.80) - c * 30 * flip,
          size.height * 0.65 + s * 35),
      size.width * 0.45,
      const Color(0xFF064E3B).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t || old.reversed != reversed;
}
