import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../domain/entities/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_members_provider.dart';

class ProjectMembersScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends ConsumerState<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    // We will fetch members here later
  }

  void _showInviteDialog(BuildContext context, ThemeData theme) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: 'Enter member email',
            labelText: 'Email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              
              final success = await ref.read(projectMembersProvider(widget.projectId).notifier)
                  .inviteMember(emailController.text.trim());
                  
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member invited successfully!'), backgroundColor: AppColors.success),
                  );
                } else {
                  final error = ref.read(projectMembersProvider(widget.projectId)).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Failed to invite member'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
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
              onPressed: () => _showInviteDialog(context, theme),
              icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              label: const Text('Invite', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                return _buildMemberRow(member, index, theme, isOwner);
              },
            ),
    );
  }

  Widget _buildMemberRow(UserEntity member, int index, ThemeData theme, bool isOwner) {
    final roleText = member.role ?? 'Member';
    final isAdmin = roleText.toLowerCase() == 'admin' || roleText.toLowerCase() == 'owner' || roleText.toLowerCase() == 'leader';
    final roleColor = isAdmin ? Colors.orange : AppColors.grey400;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(member.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        if (isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey400),
            onSelected: (value) async {
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
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Admin',
                child: Text('Make Admin'),
              ),
              const PopupMenuItem(
                value: 'Member',
                child: Text('Make Member'),
              ),
            ],
          ),
      ],
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05);
  }
}
