import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(authNotifierProvider).user;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator())
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchDashboardStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      backgroundColor: Colors.white,
                      child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: AppColors.primary)),
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final dashboardState = ref.watch(dashboardProvider);
                    return dashboardState.when(
                      data: (dashboard) => Row(
                        children: [
                          _buildStatCard('Tasks Done', '${dashboard.totalTasksDone}', theme),
                          const SizedBox(width: AppSizes.md),
                          _buildStatCard('Ongoing', '${dashboard.totalTasksOngoing}', theme),
                        ],
                      ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error loading stats: $e', style: const TextStyle(color: AppColors.error)),
                    );
                  },
                ),
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
                    _buildMenuItem(
                      Icons.dark_mode_outlined,
                      'Dark Mode',
                      theme,
                      trailing: Switch(
                        value: isDark,
                        onChanged: (v) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    _buildMenuItem(Icons.language_outlined, 'Language', theme, trailing: const Text('English')),
                    _buildMenuItem(Icons.notifications_outlined, 'Notifications', theme),
                    const Divider(),
                    _buildMenuItem(Icons.logout_rounded, 'Logout', theme, textColor: AppColors.error, onTap: () async {
                      // Call logout to clear tokens and session
                      await ref.read(authNotifierProvider.notifier).logout();
                      
                      // Clear Riverpod states for all features
                      ref.invalidate(workspaceNotifierProvider);
                      ref.invalidate(projectNotifierProvider);
                      ref.invalidate(taskNotifierProvider);
                      ref.invalidate(notificationProvider);
                      ref.invalidate(dashboardProvider);
                      
                      if (context.mounted) {
                        // Navigate back to Login and clear stack
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                      }
                    }),
                  ],
                ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
              ),
              const SizedBox(height: 100), // Add padding at bottom for pull-to-refresh
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light ? AppColors.grey200.withOpacity(0.5) : Colors.black12,
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
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: textColor)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}

