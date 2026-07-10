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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchDashboardStats();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Floating Header with Gradient
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6), Color(0xFFF43F5E)],
                        ),
                      ),
                    ),
                    
                    // Profile Info
                    Positioned(
                      bottom: AppSizes.xl,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              child: Text(
                                user.fullName[0].toUpperCase(), 
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            user.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ).animate().fadeIn(delay: 200.ms),
                          Text(
                            user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Section (Bento Style)
                    Consumer(
                      builder: (context, ref, child) {
                        final dashboardState = ref.watch(dashboardProvider);
                        return dashboardState.when(
                          data: (dashboard) => Row(
                            children: [
                              _buildStatCard('Tasks Done', '${dashboard.totalTasksDone}', AppColors.success, Icons.check_circle_rounded, theme),
                              const SizedBox(width: AppSizes.md),
                              _buildStatCard('Ongoing', '${dashboard.totalTasksOngoing}', AppColors.info, Icons.autorenew_rounded, theme),
                            ],
                          ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Text('Error loading stats: $e', style: const TextStyle(color: AppColors.error)),
                        );
                      },
                    ),

                    const SizedBox(height: AppSizes.xxl),

                    // Settings Menu
                    Text(
                      'Settings',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: AppSizes.md),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grey200.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            Icons.dark_mode_rounded,
                            'Dark Mode',
                            theme,
                            trailing: Switch(
                              value: isDark,
                              activeColor: AppColors.primary,
                              onChanged: (v) {
                                ref.read(themeProvider.notifier).toggleTheme();
                              },
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.1, delay: 300.ms).fadeIn(),

                    const SizedBox(height: AppSizes.xl),

                    // Logout Button
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: _buildMenuItem(
                        Icons.logout_rounded,
                        'Logout',
                        theme,
                        textColor: AppColors.error,
                        onTap: () async {
                          await ref.read(authNotifierProvider.notifier).logout();
                          
                          ref.invalidate(workspaceNotifierProvider);
                          ref.invalidate(projectNotifierProvider);
                          ref.invalidate(taskNotifierProvider);
                          ref.invalidate(notificationProvider);
                          ref.invalidate(dashboardProvider);
                          
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                          }
                        },
                      ),
                    ).animate().slideY(begin: 0.1, delay: 400.ms).fadeIn(),

                    const SizedBox(height: 100), // padding at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSizes.md),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w900)),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, ThemeData theme, {Widget? trailing, VoidCallback? onTap, Color? textColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: textColor ?? AppColors.primary, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: textColor ?? theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
      onTap: onTap,
    );
  }
}
