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
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        ref.invalidate(workspaceNotifierProvider);
        ref.invalidate(projectNotifierProvider);
        ref.invalidate(taskNotifierProvider);
        ref.invalidate(notificationProvider);
        ref.invalidate(dashboardProvider);

        Navigator.pushNamedAndRemoveUntil(context, '/workspaces', (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFFEDD5), Color(0xFFFDE68A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Title
                const Icon(Icons.check_circle_outline_rounded, size: 60, color: AppColors.primary)
                    .animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: AppSizes.md),
                Text(
                  'TaskFlow',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: -1,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2),
                const SizedBox(height: AppSizes.xxl),

                // Glass Card
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: AppSizes.md),

                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        theme: theme,
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05),
                      const SizedBox(height: AppSizes.md),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        theme: theme,
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.05),
                      const SizedBox(height: AppSizes.md),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isConfirm: false,
                        theme: theme,
                      ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.05),
                      const SizedBox(height: AppSizes.md),

                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isConfirm: true,
                        theme: theme,
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.05),
                      const SizedBox(height: AppSizes.xl),

                      // Register Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  if (_passwordController.text != _confirmPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                                    );
                                    return;
                                  }
                                  ref.read(authNotifierProvider.notifier).register(
                                        _nameController.text.trim(),
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
                            elevation: 5,
                            shadowColor: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'Sign Up',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ).animate().fadeIn(delay: 900.ms).scale(),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSizes.xl),
                // Login prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: AppColors.grey600)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
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
    bool isConfirm = false,
  }) {
    final bool isObscured = isConfirm ? _obscureConfirmPassword : _obscurePassword;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey400),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey400,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }
}
