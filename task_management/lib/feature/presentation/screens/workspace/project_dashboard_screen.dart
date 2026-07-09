import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/project_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../../domain/entities/workspace_entity.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  final String workspaceId;
  
  const ProjectDashboardScreen({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectState = ref.watch(projectNotifierProvider(workspaceId));
    final projects = projectState.projects;
    final workspaceState = ref.watch(workspaceNotifierProvider);
    final workspaceName = workspaceState.workspaces.firstWhere((w) => w.id == workspaceId, orElse: () => WorkspaceEntity(id: '', name: 'Workspace Dashboard', description: '', ownerId: '', logoUrl: null, createdAt: DateTime.now(), updatedAt: DateTime.now())).name;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectNotifierProvider(workspaceId).notifier).fetchProjects(workspaceId);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                // IconButton(
                //   icon: const Icon(Icons.people_outline_rounded, color: Colors.white),
                //   onPressed: () {
                //     Navigator.pushNamed(context, AppRoutes.projectMembers);
                //   },
                // ),
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
                              workspaceName,
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(),
                          const SizedBox(height: 8),
                          Text(
                            'Project Dashboard',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
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
                          onPressed: () => _showCreateProjectDialog(context, ref, theme),
                          icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                          label: const Text('New', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),

                    const SizedBox(height: AppSizes.md),

                    // Projects List
                    projectState.isLoading && projects.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projects.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.lg),
                      itemBuilder: (context, index) {
                        final proj = projects[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to Kanban Board
                            Navigator.pushNamed(context, AppRoutes.taskBoard, arguments: {
                              'projectId': proj.id,
                              'projectName': proj.name,
                              'workspaceName': workspaceName,
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.xl),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                              border: Border.all(color: theme.dividerColor),
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
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.grey600),
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Project?'),
                                              content: const Text('This will permanently delete the project and all its tasks. Are you sure?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final success = await ref.read(projectNotifierProvider(workspaceId).notifier).deleteProject(workspaceId, proj.id);
                                            if (success && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted.')));
                                            } else if (context.mounted) {
                                              final error = ref.read(projectNotifierProvider(workspaceId)).error;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete project')));
                                            }
                                          }
                                        } else if (value == 'leave') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Leave Project?'),
                                              content: const Text('Are you sure you want to leave this project?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Leave', style: TextStyle(color: Colors.orange)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final success = await ref.read(projectNotifierProvider(workspaceId).notifier).leaveProject(proj.id);
                                            if (success && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You left the project.')));
                                              // Refresh workspace to check if it should still be displayed
                                              ref.read(workspaceNotifierProvider.notifier).fetchWorkspaces();
                                            } else if (context.mounted) {
                                              final error = ref.read(projectNotifierProvider(workspaceId)).error;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to leave project')));
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'leave',
                                          child: Row(
                                            children: [
                                              Icon(Icons.exit_to_app, color: Colors.orange, size: 20),
                                              SizedBox(width: 8),
                                              Text('Leave Project', style: TextStyle(color: Colors.orange)),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                // Progress bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Progress', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.grey600)),
                                    Text('${proj.progress}%', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: proj.progress / 100.0,
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
            Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref, ThemeData theme) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(projectNotifierProvider(workspaceId).notifier)
                    .createProject(workspaceId, nameController.text.trim(), descController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
