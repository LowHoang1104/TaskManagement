import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../../mock_data.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = MockData.tasks.first; 
    final tags = MockData.getTags(MockData.taskTagsMap[task.id] ?? []);
    final assignee = MockData.getUserById(task.assigneeId);
    final reporter = MockData.getUserById(task.reporterId);

    return Scaffold(
      backgroundColor: Colors.white,
      // Use a Stack to pin a glassmorphism comment bar at the bottom
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.more_horiz_rounded, color: Colors.white), onPressed: () {}),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFD1FAE5), Color(0xFFFEF3C7)], // Soft Green/Yellow
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0, bottom: 0,
                        child: Image.asset(
                          'assets/images/task_detail_illustration.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSizes.xl, right: AppSizes.xl, top: AppSizes.xl, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project path & Task ID
                Row(
                  children: [
                    Text('TaskFlow Mobile App', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 8),
                    Text('TSK-124', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: AppSizes.md),

                // Title
                Text(
                  task.title,
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.2),
                ).animate().slideX(begin: -0.05).fadeIn(),

                const SizedBox(height: AppSizes.md),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) {
                    final c = Color(int.parse(t.color.replaceFirst('#', '0xFF')));
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: c.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        t.name,
                        style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: AppSizes.xl),

                // Grid Metadata
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    children: [
                      _buildGridRow('Assignee', _buildUserBadge(assignee, theme), 'Reporter', _buildUserBadge(reporter, theme), theme),
                      const Padding(padding: EdgeInsets.symmetric(vertical: AppSizes.md), child: Divider(height: 1)),
                      _buildGridRow('Priority', _buildPriorityBadge(task.priority, theme), 'Due Date', _buildDateBadge(task.deadline, theme), theme),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),

                const SizedBox(height: AppSizes.xl),

                // Description
                Text('Description', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: AppSizes.sm),
                Text(
                  task.description ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: AppSizes.xxl),

                // Attachments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attachments (2)', style: theme.textTheme.titleMedium),
                    IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {}),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: AppSizes.xs),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildAttachmentCard('UI_Mockup_v1.pdf', '2.4 MB', Icons.picture_as_pdf_rounded, Colors.red),
                      const SizedBox(width: AppSizes.md),
                      _buildAttachmentCard('Brand_Assets.zip', '15 MB', Icons.folder_zip_rounded, Colors.blue),
                    ],
                  ),
                ).animate().slideX(begin: 0.1, delay: 400.ms).fadeIn(),

                const SizedBox(height: AppSizes.xxl),

                // Activity / Comments
                Text('Activity', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: AppSizes.md),
                _buildCommentItem(MockData.userHuy, 'Hey Long, please make sure the padding is exactly 16px as per the design system.', '2 hours ago', theme),
                const SizedBox(height: AppSizes.lg),
                _buildCommentItem(MockData.currentUser, 'Got it! I will update the pull request shortly.', 'Just now', theme),

              ],
            ),
          ),
        ),
      ],
    ),

          // Bottom Action Bar (Glassmorphism)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: AppColors.grey200.withValues(alpha: 0.5))),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        CircleAvatar(radius: 18, backgroundImage: NetworkImage(MockData.currentUser.avatarUrl!)),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Text('Add a comment...', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: 1, delay: 600.ms, curve: Curves.easeOutExpo),
        ],
      ),
    );
  }

  Widget _buildGridRow(String label1, Widget val1, String label2, Widget val2, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
              const SizedBox(height: 6),
              val1,
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
              const SizedBox(height: 6),
              val2,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserBadge(UserEntity user, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 10, backgroundImage: NetworkImage(user.avatarUrl!)),
        const SizedBox(width: 8),
        Text(user.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority, ThemeData theme) {
    Color c = AppColors.grey600;
    String t = 'Normal';
    IconData icon = Icons.circle;
    if (priority == TaskPriority.high) { c = Colors.orange; t = 'High'; icon = Icons.keyboard_arrow_up_rounded; }
    if (priority == TaskPriority.critical) { c = AppColors.error; t = 'Critical'; icon = Icons.keyboard_double_arrow_up_rounded; }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(t, style: theme.textTheme.bodyMedium?.copyWith(color: c, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDateBadge(DateTime? date, ThemeData theme) {
    if (date == null) return Text('No due date', style: theme.textTheme.bodyMedium);
    final isOverdue = date.isOverdue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: isOverdue ? AppColors.error : AppColors.grey800),
        const SizedBox(width: 6),
        Text(date.displayDate, style: theme.textTheme.bodyMedium?.copyWith(
          color: isOverdue ? AppColors.error : AppColors.grey800,
          fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
        )),
      ],
    );
  }

  Widget _buildAttachmentCard(String name, String size, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSizes.sm),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(size, style: const TextStyle(color: AppColors.grey600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(UserEntity user, String comment, String timeAgo, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 16, backgroundImage: NetworkImage(user.avatarUrl!)),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(user.fullName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSizes.sm),
                  Text(timeAgo, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey400)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: user.id == MockData.currentUser.id ? AppColors.primary.withValues(alpha: 0.1) : AppColors.grey50,
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(AppSizes.radiusLg),
                    bottomLeft: const Radius.circular(AppSizes.radiusLg),
                    bottomRight: const Radius.circular(AppSizes.radiusLg),
                    topLeft: user.id == MockData.currentUser.id ? const Radius.circular(AppSizes.radiusLg) : const Radius.circular(0),
                  ),
                  border: Border.all(color: user.id == MockData.currentUser.id ? AppColors.primary.withValues(alpha: 0.2) : AppColors.grey200),
                ),
                child: Text(comment, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }
}
