import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.verifyEmail,
          arguments: _emailController.text.trim().isEmpty
              ? 'an.nguyen@acme.co'
              : _emailController.text.trim(),
        );
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
                label: 'Create account',
                loading: authState.isLoading,
                onTap: () => ref.read(authNotifierProvider.notifier).register(
                      _nameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text,
                    ),
              ),

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account?  ',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.text3),
                      children: [
                        TextSpan(
                            text: 'Sign in',
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
