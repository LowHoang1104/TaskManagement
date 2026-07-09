import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (next.user != null) {
        // Clear all cached global providers before navigating into the app
        // This ensures the new user gets fresh data instead of the previous user's or a 401 cache
        ref.invalidate(workspaceNotifierProvider);
        ref.invalidate(projectNotifierProvider);
        ref.invalidate(taskNotifierProvider);
        ref.invalidate(notificationProvider);
        ref.invalidate(dashboardProvider);

        Navigator.pushReplacementNamed(context, AppRoutes.workspaceList);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Illustration & Branding
            Stack(
              children: [
                // Fresh vibrant gradient background
                Container(
                  height: 380,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)], // Very light indigo to purple
                    ),
                  ),
                ),
                
                // Generated 3D Illustration
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/login_illustration.png',
                    height: 380,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Overlay text
                Positioned(
                  bottom: AppSizes.xl,
                  left: AppSizes.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'TaskFlow',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Welcome\nBack!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(),
                    ],
                  ),
                ),
              ],
            ),

            // Form Area
            Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log in to continue managing your projects.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: AppSizes.xl),

                  // Email Input
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    theme: theme,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.lg),

                  // Password Input
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    theme: theme,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.md),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: AppSizes.xl),

                  // Login Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref.read(authNotifierProvider.notifier).login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).scale(),

                  const SizedBox(height: AppSizes.xxl),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1100.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey400),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey400,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
