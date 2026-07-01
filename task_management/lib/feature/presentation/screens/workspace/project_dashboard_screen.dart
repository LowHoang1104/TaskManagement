import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../mock_data.dart';

class ProjectDashboardScreen extends StatelessWidget {
  const ProjectDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = MockData.projects;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.people_outline_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.projectMembers);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Base
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFFFFEDD5), Color(0xFFFEE2E2)], // Soft Orange/Red gradient
                      ),
                    ),
                  ),
                  
                  // Generated 3D Illustration
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/project_illustration.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Overlay text (Title)
                  Positioned(
                    bottom: AppSizes.xl,
                    left: AppSizes.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Omega Dev',
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideX(),
                        const SizedBox(height: 8),
                        Text(
                          'Project Dashboard',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10)
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header stats
                  Row(
                    children: [
                      _buildStatCard('Total Projects', '${projects.length}', theme, Icons.folder_open_rounded, AppColors.info),
                      const SizedBox(width: AppSizes.md),
                      _buildStatCard('Active Tasks', '12', theme, Icons.check_circle_outline_rounded, AppColors.success),
                    ],
                  ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),

                  const SizedBox(height: AppSizes.xxl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Projects',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn(delay: 200.ms),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                        label: const Text('New', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Projects List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSizes.lg),
                    itemBuilder: (context, index) {
                      final proj = projects[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to Kanban Board
                          Navigator.pushNamed(context, AppRoutes.taskBoard);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.xl),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                            border: Border.all(color: AppColors.grey100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grey200.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      proj.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.grey50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                proj.description ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSizes.xl),
                              // Mock progress bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Progress', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.grey600)),
                                  Text('60%', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: 0.6, // 60%
                                backgroundColor: AppColors.grey100,
                                color: AppColors.primary,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ).animate().slideY(begin: 0.1, delay: (200 + 100 * index).ms, duration: 400.ms).fadeIn(),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, ThemeData theme, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.grey800, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
