import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../domain/entities/entities.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_members_provider.dart';
import '../../providers/workspace_members_provider.dart';

class ProjectMembersScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String workspaceId;
  const ProjectMembersScreen({super.key, required this.projectId, required this.workspaceId});

  @override
  ConsumerState<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends ConsumerState<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    // We will fetch members here later
  }

  void _showInviteBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final wsMembersState = ref.watch(workspaceMembersProvider(widget.workspaceId));
                final projMembersState = ref.watch(projectMembersProvider(widget.projectId));
                
                final wsMembers = wsMembersState.members;
                final projMemberIds = projMembersState.members.map((m) => m.id).toSet();
                
                final availableMembers = wsMembers.where((m) => !projMemberIds.contains(m.id)).toList();

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSizes.md),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Text(
                        'Add Workspace Member to Project',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: wsMembersState.isLoading && wsMembers.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : availableMembers.isEmpty
                              ? Center(
                                  child: Text(
                                    'No available workspace members to add.',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: availableMembers.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                                  itemBuilder: (context, index) {
                                    final member = availableMembers[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        backgroundImage: ApiUtils.getFullImageUrl(member.avatarUrl) != null ? NetworkImage(ApiUtils.getFullImageUrl(member.avatarUrl)!) : null,
                                        child: ApiUtils.getFullImageUrl(member.avatarUrl) == null ? Text(
                                          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white),
                                        ) : null,
                                      ),
                                      title: Text(member.fullName),
                                      subtitle: Text(member.email),
                                      trailing: TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final success = await ref.read(projectMembersProvider(widget.projectId).notifier)
                                              .inviteMember(member.email);
                                          if (mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Member added successfully!'), backgroundColor: AppColors.success),
                                              );
                                            } else {
                                              final error = ref.read(projectMembersProvider(widget.projectId)).error;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(error ?? 'Failed to add member'), backgroundColor: AppColors.error),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Add'),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersState = ref.watch(projectMembersProvider(widget.projectId));
    final members = membersState.members;
    
    final currentUser = ref.watch(authNotifierProvider).user;
    final currentMember = members.firstWhere((m) => m.id == currentUser?.id, orElse: () => UserEntity(id: '', fullName: '', email: '', passwordHash: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final isOwner = currentMember.role == 'Owner';
    final isAdminOrOwner = isOwner || currentMember.role == 'Admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Members',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isAdminOrOwner)
            TextButton.icon(
              onPressed: () => _showInviteBottomSheet(context, theme),
              icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              label: const Text('Add Member', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: membersState.isLoading && members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.xl),
              itemCount: members.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Divider(height: 1, color: theme.dividerColor),
              ),
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildMemberRow(member, index, theme, isOwner, isAdminOrOwner);
              },
            ),
    );
  }

  Widget _buildMemberRow(UserEntity member, int index, ThemeData theme, bool isOwner, bool isAdminOrOwner) {
    final roleText = member.role ?? 'Member';
    final isAdmin = roleText.toLowerCase() == 'admin' || roleText.toLowerCase() == 'owner' || roleText.toLowerCase() == 'leader';
    final roleColor = isAdmin ? Colors.orange : AppColors.grey400;

    final avatarUrl = ApiUtils.getFullImageUrl(member.avatarUrl);

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null 
              ? Text(member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.fullName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                member.email,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600),
              ),
            ],
          ),
        ),
        if (member.status == 'Pending')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Pending',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: roleColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            roleText,
            style: theme.textTheme.labelSmall?.copyWith(color: roleColor, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        const SizedBox(width: AppSizes.sm),
        if (isAdminOrOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey400),
            onSelected: (value) async {
              if (value == 'remove') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove Member?'),
                    content: Text('Are you sure you want to remove ${member.fullName} from the project?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await ref.read(projectMembersProvider(widget.projectId).notifier)
                      .removeMember(member.id);
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Member removed from project'), backgroundColor: AppColors.success),
                      );
                    } else {
                      final error = ref.read(projectMembersProvider(widget.projectId)).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Failed to remove member'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                }
              } else {
                final success = await ref.read(projectMembersProvider(widget.projectId).notifier)
                    .updateRole(member.id, value);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Role updated to $value'), backgroundColor: AppColors.success),
                    );
                  } else {
                    final error = ref.read(projectMembersProvider(widget.projectId)).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Failed to update role'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (isOwner) ...[
                const PopupMenuItem(
                  value: 'Admin',
                  child: Text('Make Admin'),
                ),
                const PopupMenuItem(
                  value: 'Member',
                  child: Text('Make Member'),
                ),
              ],
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Remove from Project', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05);
  }
}
