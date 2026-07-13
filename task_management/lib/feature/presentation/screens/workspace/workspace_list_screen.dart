import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_members_provider.dart';
import '../notification/notification_screen.dart';

class WorkspaceListScreen extends ConsumerWidget {
  const WorkspaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceNotifierProvider);
    final workspaces = workspaceState.workspaces;
    final currentUser = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(workspaceNotifierProvider.notifier).fetchWorkspaces();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Collapsible Image Header
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(notificationProvider).unreadCount;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
                ),
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // Primary to Secondary
                        ),
                      ),
                    ),
                    
                    // Decorative shapes (optional)
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
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
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(),
                          const SizedBox(height: 4),
                          Text(
                            'Select a workspace to view projects',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Workspace Grid List
            workspaceState.isLoading && workspaces.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSizes.md,
                        mainAxisSpacing: AppSizes.md,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == workspaces.length) {
                            return _buildAddWorkspaceCard(context, ref, theme);
                          }
                          final ws = workspaces[index];
                          return _buildWorkspaceCard(context, ref, ws, theme, index, currentUser?.id);
                        },
                        childCount: workspaces.length + 1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref, ThemeData theme) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Workspace Name'),
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
                ref.read(workspaceNotifierProvider.notifier)
                    .createWorkspace(nameController.text.trim(), descController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, WidgetRef ref, dynamic ws, ThemeData theme, int index, String? currentUserId) {
    return GestureDetector(
      onTap: () {
        // Navigate to project detail (dashboard for this workspace)
        Navigator.pushNamed(context, AppRoutes.projectDetail, arguments: ws.id);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: theme.dividerColor),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspaces_outline, color: AppColors.primary),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.grey600),
                  onSelected: (value) async {
                    if (value == 'members') {
                      Navigator.pushNamed(context, AppRoutes.workspaceMembers, arguments: ws.id);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Workspace?'),
                          content: const Text('This will move the workspace to trash. Are you sure?'),
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
                        final success = await ref.read(workspaceNotifierProvider.notifier).deleteWorkspace(ws.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workspace deleted.')));
                        } else if (context.mounted) {
                          final error = ref.read(workspaceNotifierProvider).error;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete workspace')));
                        }
                      }
                    } else if (value == 'leave') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Leave Workspace?'),
                          content: const Text('Are you sure you want to leave this workspace?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Leave', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true && currentUserId != null) {
                        final success = await ref.read(workspaceMembersProvider(ws.id).notifier).removeMember(currentUserId);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left workspace successfully')));
                          ref.read(workspaceNotifierProvider.notifier).fetchWorkspaces(); // Refresh list
                        } else if (context.mounted) {
                          final error = ref.read(workspaceMembersProvider(ws.id)).error;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to leave workspace')));
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'members',
                      child: Row(
                        children: [
                          Icon(Icons.group_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Members', style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (currentUserId == ws.ownerId)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Leave Workspace', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
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

  Widget _buildAddWorkspaceCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        // Mock prompt to create workspace
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('New Workspace'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Workspace Name'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Create')),
              ],
            );
          },
        );

        if (name != null && name.trim().isNotEmpty) {
          await ref.read(workspaceNotifierProvider.notifier).createWorkspace(name.trim(), 'A newly created workspace');
        }
      },
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
