import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../taskflow/widgets/tf_widgets.dart';

/// Create account — redesigned to match `TaskFlow.dc.html` (01 — Onboarding).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  int _countdown = 60;
  Timer? _timer;

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: p.danger),
        );
      }
      if (next.user != null) {
        ref.invalidate(workspaceNotifierProvider);
        ref.invalidate(projectNotifierProvider);
        ref.invalidate(taskNotifierProvider);
        ref.invalidate(notificationProvider);
        ref.invalidate(dashboardProvider);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () {
                // Login navigates here with pushReplacement, so there is often
                // nothing to pop back to — fall back to the login screen.
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              }),
              const SizedBox(height: 18),
              Text('Create account',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: p.text)),
              const SizedBox(height: 5),
              Text('Start organising in under a minute.',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: p.text3)),
              const SizedBox(height: 26),

              if (!_otpSent) ...[
                TfLabeledField(
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                    controller: _nameController,
                    hint: 'An Nguyen'),
                const SizedBox(height: 14),
                TfLabeledField(
                    label: 'Email',
                    icon: Icons.mail_outline_rounded,
                    controller: _emailController,
                    hint: 'an.nguyen@acme.co',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                TfLabeledField(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    obscure: true,
                    hint: '••••••'),

                const SizedBox(height: 14),
                _StrengthMeter(controller: _passwordController),

                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.check_rounded, size: 15, color: p.onAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: p.text2),
                          children: [
                            TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, color: p.accent)),
                            const TextSpan(text: ' and '),
                            TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, color: p.accent)),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                TfPrimaryButton(
                  label: 'Send OTP',
                  loading: authState.isLoading,
                  onTap: () async {
                    if (_emailController.text.trim().isEmpty) return;
                    final success = await ref.read(authNotifierProvider.notifier).sendOtp(_emailController.text.trim());
                    if (success) {
                      setState(() => _otpSent = true);
                      _startTimer();
                    }
                  },
                ),
              ] else ...[
                Text('Enter the 6-digit code sent to\n${_emailController.text.trim()}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                const SizedBox(height: 26),
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    defaultPinTheme: PinTheme(
                      width: 48,
                      height: 56,
                      textStyle: TextStyle(
                          fontSize: 20, color: p.text, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.border2),
                        borderRadius: BorderRadius.circular(12),
                        color: p.surface2,
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 48,
                      height: 56,
                      textStyle: TextStyle(
                          fontSize: 20, color: p.text, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.accent),
                        borderRadius: BorderRadius.circular(12),
                        color: p.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _countdown > 0
                        ? null
                        : () async {
                            final success = await ref.read(authNotifierProvider.notifier).sendOtp(_emailController.text.trim());
                            if (success) _startTimer();
                          },
                    child: Text(
                      _countdown > 0
                          ? 'Resend code in ${_countdown}s'
                          : 'Resend code now',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _countdown > 0 ? p.text3 : p.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TfPrimaryButton(
                  label: 'Verify & Create Account',
                  loading: authState.isLoading,
                  onTap: () {
                    if (_otpController.text.length == 6) {
                      ref.read(authNotifierProvider.notifier).verifyOtpAndRegister(
                            _emailController.text.trim(),
                            _otpController.text,
                            _passwordController.text,
                            _nameController.text.trim(),
                          );
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (_otpSent) {
                      setState(() {
                        _otpSent = false;
                        _timer?.cancel();
                      });
                    } else {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      text: _otpSent ? '' : 'Already have an account?  ',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.text3),
                      children: [
                        TextSpan(
                            text: _otpSent ? 'Change email' : 'Sign in',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: p.accent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.arrow_back_rounded, size: 24, color: p.text2),
    );
  }
}

/// Live password-strength meter (3 segments) matching the design.
class _StrengthMeter extends StatelessWidget {
  final TextEditingController controller;
  const _StrengthMeter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final len = controller.text.length;
        final score = len == 0 ? 0 : (len < 6 ? 1 : (len < 10 ? 2 : 3));
        const labels = ['', 'Weak', 'Good', 'Strong'];
        final colors = [p.surface3, p.danger, p.accent, p.success];
        Widget seg(int i) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: i < score ? colors[score] : p.surface3,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
        return Row(
          children: [
            seg(0),
            seg(1),
            seg(2),
            const SizedBox(width: 10),
            Text(score == 0 ? '' : labels[score],
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: p.text2)),
          ],
        );
      },
    );
  }
}
