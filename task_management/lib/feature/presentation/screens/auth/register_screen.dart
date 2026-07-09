import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Illustration & Branding
            Stack(
              children: [
                // Fresh vibrant gradient background
                Container(
                  height: 320,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFFFEF3C7), Color(0xFFFFEDD5)], // Soft amber/orange tone
                    ),
                  ),
                ),
                
                // Generated 3D Illustration
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/register_illustration.png',
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),

                // Back button
                Positioned(
                  top: 50,
                  left: AppSizes.md,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey800),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ).animate().fadeIn(),
                
                // Overlay text
                Positioned(
                  bottom: AppSizes.xl,
                  left: AppSizes.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Us!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(),
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
                    'Create an account to start organizing your life and team.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppSizes.xl),

                  // Full Name Input
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    theme: theme,
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.lg),

                  // Email Input
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    theme: theme,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.lg),

                  // Password Input
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    isObscured: _obscurePassword,
                    onToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    theme: theme,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.lg),

                  // Confirm Password Input
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    isObscured: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    theme: theme,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSizes.xxl),

                  // Register Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              if (_passwordController.text != _confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
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
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).scale(),

                  const SizedBox(height: AppSizes.xl),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600)),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey400),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggle,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.grey400),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.grey400,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
