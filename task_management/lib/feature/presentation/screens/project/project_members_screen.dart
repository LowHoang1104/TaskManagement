import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../domain/entities/entities.dart';
import '../../../mock_data.dart';

class ProjectMembersScreen extends StatelessWidget {
  const ProjectMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // For mock purposes, just list all available users
    final members = [
      MockData.currentUser,
      MockData.userHuy,
      MockData.userLinh,
      MockData.userTuan,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.grey800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Members',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.grey900),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Mock invite action
            },
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            label: const Text('Invite', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.xl),
        itemCount: members.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Divider(height: 1, color: AppColors.grey100),
        ),
        itemBuilder: (context, index) {
          final member = members[index];
          return _buildMemberRow(member, index, theme);
        },
      ),
    );
  }

  Widget _buildMemberRow(UserEntity member, int index, ThemeData theme) {
    // Mock Roles: first user is Owner, others are Members
    final isOwner = index == 0;
    final roleText = isOwner ? 'Owner' : 'Member';
    final roleColor = isOwner ? Colors.orange : AppColors.grey400;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(member.avatarUrl!),
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
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey400),
          onPressed: () {},
        ),
      ],
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05);
  }
}
