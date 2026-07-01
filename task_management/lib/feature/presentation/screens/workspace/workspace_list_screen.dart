import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../mock_data.dart';

class WorkspaceListScreen extends StatelessWidget {
  const WorkspaceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaces = MockData.workspaces;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
              const SizedBox(width: AppSizes.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Base
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)], // Soft Blue/Teal gradient
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
                      'assets/images/workspace_illustration.png',
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
                        Text(
                          'Your Workspaces',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 4),
                        Text(
                          'Select a workspace to view projects',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideX(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Workspace Grid List
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.md,
                mainAxisSpacing: AppSizes.md,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == workspaces.length) {
                    return _buildAddWorkspaceCard(theme);
                  }
                  final ws = workspaces[index];
                  return _buildWorkspaceCard(context, ws, theme, index);
                },
                childCount: workspaces.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, dynamic ws, ThemeData theme, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to project detail (dashboard for this workspace)
        Navigator.pushNamed(context, AppRoutes.projectDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.grey100),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey200.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspaces_outline, color: AppColors.primary),
            ),
            const Spacer(),
            Text(
              ws.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              ws.description ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().scale(delay: (100 * index).ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildAddWorkspaceCard(ThemeData theme) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 40, color: AppColors.primary),
              SizedBox(height: AppSizes.sm),
              Text('Create New', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}
