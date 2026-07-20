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
import 'forgot_password_screen.dart';

/// Sign in — redesigned to match `TaskFlow.dc.html` (01 — Onboarding).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'an.nguyen@acme.co');
  final _passwordController = TextEditingController();

  @override
  void dispose() {
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
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
      }
    });

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TfLogoTile(),
              const SizedBox(height: 26),
              Text('Welcome back',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: p.text)),
              const SizedBox(height: 5),
              Text('Sign in to keep your work flowing.',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: p.text3)),
              const SizedBox(height: 26),

              // Segmented tab
              _AuthTabs(
                index: 0,
                onRegister: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.register),
              ),
              const SizedBox(height: 22),

              TfLabeledField(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TfLabeledField(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscure: true,
                hint: '••••••••',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TfPrimaryButton(
                label: 'Sign in',
                loading: authState.isLoading,
                onTap: () => ref.read(authNotifierProvider.notifier).login(
                      _emailController.text.trim(),
                      _passwordController.text,
                    ),
              ),
              const SizedBox(height: 20),

              _OrDivider(),
              const SizedBox(height: 20),
              _GoogleButton(
                onTap: () => ref.read(authNotifierProvider.notifier).googleLogin(),
              ),

              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.register),
                  child: Text.rich(
                    TextSpan(
                      text: 'New here?  ',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.text3),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: p.accent),
                        ),
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

/// The "Sign in / Register" segmented control.
class _AuthTabs extends StatelessWidget {
  final int index; // 0 = sign in, 1 = register
  final VoidCallback? onRegister;
  const _AuthTabs({required this.index, this.onRegister});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget tab(String label, bool active, VoidCallback? onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? p.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1))
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? p.text : p.text3)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab('Sign in', index == 0, null),
          tab('Register', index == 1, onRegister),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: p.text3)),
        ),
        Expanded(child: Divider(color: p.border, height: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _GoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: p.border2, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('G',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: p.accent)),
            const SizedBox(width: 9),
            Text('Google',
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text)),
          ],
        ),
      ),
    );
  }
}
