import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = MockData.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusXl),
                  bottomRight: Radius.circular(AppSizes.radiusXl),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.avatarUrl!),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    user.fullName,
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ).animate().fadeIn(delay: 200.ms),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Row(
                children: [
                  _buildStatCard('Tasks Done', '45', theme),
                  const SizedBox(width: AppSizes.md),
                  _buildStatCard('Ongoing', '12', theme),
                ],
              ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
            ),

            const SizedBox(height: AppSizes.xxl),

            // Settings Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSizes.md),
                  _buildMenuItem(Icons.dark_mode_outlined, 'Dark Mode', theme, trailing: Switch(value: false, onChanged: (v) {})),
                  _buildMenuItem(Icons.language_outlined, 'Language', theme, trailing: const Text('English')),
                  _buildMenuItem(Icons.notifications_outlined, 'Notifications', theme),
                  const Divider(),
                  _buildMenuItem(Icons.logout_rounded, 'Logout', theme, textColor: AppColors.error, onTap: () {
                    // Navigate back to Login and clear stack
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  }),
                ],
              ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey200.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSizes.xs),
            Text(title, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, ThemeData theme, {Widget? trailing, VoidCallback? onTap, Color? textColor}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textColor ?? AppColors.primary),
      ),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: textColor ?? AppColors.grey800)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}
