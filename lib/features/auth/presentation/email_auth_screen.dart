import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_service.dart';
import '../application/auth_provider.dart';
import '../../profile/data/profile_repository.dart';

// ─── EmailAuthScreen ──────────────────────────────────────────────────────────

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen>
    with TickerProviderStateMixin {
  bool _isSignIn = true;
  bool _isLoading = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _switchCtrl;
  late final Animation<double> _switchFade;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _suEmailCtrl = TextEditingController();
  final _suPasswordCtrl = TextEditingController();
  final _suConfirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _switchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..value = 1;
    _switchFade = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _switchCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _suEmailCtrl.dispose();
    _suPasswordCtrl.dispose();
    _suConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool toSignIn) async {
    if (_isSignIn == toSignIn) return;
    await _switchCtrl.reverse();
    setState(() => _isSignIn = toSignIn);
    _switchCtrl.forward();
  }

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
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
      _showError('Sign-in failed: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            email: _suEmailCtrl.text.trim(),
            password: _suPasswordCtrl.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.go('/profile', extra: {'setup': true});
    } catch (e) {
      if (!mounted) return;
      _showError('Sign-up failed: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Background orbs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) => CustomPaint(
              size: size,
              painter: _AuthOrbPainter(_bgCtrl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _BackButton(),
                      const Spacer(),
                      const Text(
                        'UpTrack',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Mode switcher pill
                _ModeSwitcher(isSignIn: _isSignIn, onToggle: _toggle),

                const SizedBox(height: 28),

                // Form card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _switchFade,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: _isSignIn
                            ? _SignInForm(
                                key: const ValueKey('signin'),
                                formKey: _signInFormKey,
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                obscurePass: _obscurePass,
                                onToggleObscure: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                isLoading: _isLoading,
                                onSubmit: _signIn,
                                onSwitchToSignUp: () => _toggle(false),
                              )
                            : _SignUpForm(
                                key: const ValueKey('signup'),
                                formKey: _signUpFormKey,
                                emailCtrl: _suEmailCtrl,
                                passwordCtrl: _suPasswordCtrl,
                                confirmCtrl: _suConfirmCtrl,
                                obscurePass: _obscurePass,
                                obscureConfirm: _obscureConfirm,
                                onToggleObscure: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                onToggleConfirm: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                isLoading: _isLoading,
                                onSubmit: _signUp,
                                onSwitchToSignIn: () => _toggle(true),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background orbs ──────────────────────────────────────────────────────────

class _AuthOrbPainter extends CustomPainter {
  final double t;
  _AuthOrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset c, double r, Color col) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [col, Colors.transparent],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final s = math.sin(t * math.pi);
    final co = math.cos(t * math.pi);
    orb(Offset(size.width * 0.8 + s * 50, size.height * 0.1 + co * 30),
        size.width * 0.5, const Color(0xFF3B2FA0).withValues(alpha: 0.50));
    orb(Offset(size.width * 0.1 - co * 30, size.height * 0.6 + s * 40),
        size.width * 0.45, const Color(0xFF0C4A6E).withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_AuthOrbPainter o) => o.t != t;
}

// ─── Top back button ─────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
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

// ─── Mode switcher ────────────────────────────────────────────────────────────

class _ModeSwitcher extends StatelessWidget {
  final bool isSignIn;
  final Future<void> Function(bool) onToggle;

  const _ModeSwitcher({required this.isSignIn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Sign In',
            active: isSignIn,
            onTap: () => onToggle(true),
          ),
          _ModeTab(
            label: 'Sign Up',
            active: !isSignIn,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active
                ? const Color(0xFF6366F1)
                : Colors.transparent,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared form field ────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmit;

  const _AuthField({
    required this.controller,
    required this.label,
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
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.50), fontSize: 14),
        prefixIcon:
            Icon(prefixIcon, size: 20, color: Colors.white.withValues(alpha: 0.45)),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFF87171), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
      ),
    );
  }
}

// ─── Submit button ────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton(
      {required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isLoading
                  ? []
                  : [
                      BoxShadow(
                        color:
                            const Color(0xFF6366F1).withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign In Form ─────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePass;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToSignUp;

  const _SignInForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePass,
    required this.onToggleObscure,
    required this.isLoading,
    required this.onSubmit,
    required this.onSwitchToSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue your progress.',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 28),
          _AuthField(
            controller: emailCtrl,
            label: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordCtrl,
            label: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: obscurePass,
            onToggleObscure: onToggleObscure,
            textInputAction: TextInputAction.done,
            onSubmit: onSubmit,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _SubmitButton(
              label: 'Sign In', isLoading: isLoading, onTap: onSubmit),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onSwitchToSignUp,
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 14),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirm;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToSignIn;

  const _SignUpForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onToggleObscure,
    required this.onToggleConfirm,
    required this.isLoading,
    required this.onSubmit,
    required this.onSwitchToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start tracking your goals today.',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 28),
          _AuthField(
            controller: emailCtrl,
            label: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordCtrl,
            label: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: obscurePass,
            onToggleObscure: onToggleObscure,
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'At least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: confirmCtrl,
            label: 'Confirm password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: obscureConfirm,
            onToggleObscure: onToggleConfirm,
            textInputAction: TextInputAction.done,
            onSubmit: onSubmit,
            validator: (v) {
              if (v != passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _SubmitButton(
              label: 'Create Account',
              isLoading: isLoading,
              onTap: onSubmit),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'By signing up, you agree to stay kind to your future self.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onSwitchToSignIn,
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 14),
                  children: const [
                    TextSpan(
                      text: 'Sign In',
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
