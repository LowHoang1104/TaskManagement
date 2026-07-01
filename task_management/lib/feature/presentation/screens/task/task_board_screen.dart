import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../../mock_data.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  late Map<TaskStatus, List<TaskEntity>> _groupedTasks;

  @override
  void initState() {
    super.initState();
    _groupedTasks = {
      TaskStatus.todo: MockData.tasks.where((t) => t.status == TaskStatus.todo).toList(),
      TaskStatus.doing: MockData.tasks.where((t) => t.status == TaskStatus.doing).toList(),
      TaskStatus.review: MockData.tasks.where((t) => t.status == TaskStatus.review).toList(),
      TaskStatus.done: MockData.tasks.where((t) => t.status == TaskStatus.done).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF3F4F6), // Slightly darker background for contrast
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.grey800),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TaskFlow Mobile App',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Omega Dev Workspace',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {}),
                const SizedBox(width: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: PageController(viewportFraction: 0.88),
          padEnds: false,
          children: [
            _buildColumn(TaskStatus.todo, 'CẦN LÀM', AppColors.grey600, theme),
            _buildColumn(TaskStatus.doing, 'ĐANG TIẾN HÀNH', Colors.blue, theme),
            _buildColumn(TaskStatus.review, 'CHỜ DUYỆT', Colors.orange, theme),
            _buildColumn(TaskStatus.done, 'HOÀN THÀNH', Colors.green, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(TaskStatus status, String title, Color color, ThemeData theme) {
    final tasks = _groupedTasks[status] ?? [];

    return Container(
      margin: const EdgeInsets.only(left: AppSizes.lg, top: AppSizes.md, bottom: AppSizes.xl, right: 8),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.grey200.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${tasks.length}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: AppSizes.xs),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // Task List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildPremiumTaskCard(task, theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTaskCard(TaskEntity task, ThemeData theme, int index) {
    // Determine priority info
    Color priorityColor = AppColors.grey400;
    IconData priorityIcon = Icons.keyboard_arrow_down_rounded;
    if (task.priority == TaskPriority.high) {
      priorityColor = Colors.orange;
      priorityIcon = Icons.keyboard_arrow_up_rounded;
    }
    if (task.priority == TaskPriority.critical) {
      priorityColor = AppColors.error;
      priorityIcon = Icons.keyboard_double_arrow_up_rounded;
    }

    final tags = MockData.getTags(MockData.taskTagsMap[task.id] ?? []);
    final assignee = MockData.getUserById(task.assigneeId);
    final commentCount = MockData.taskCommentsMap[task.id] ?? 0;
    final attachmentCount = MockData.taskAttachmentsMap[task.id] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.taskDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey400.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Tags & Priority
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) {
                      final c = Color(int.parse(t.color.replaceFirst('#', '0xFF')));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: c.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          t.name,
                          style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Icon(priorityIcon, color: priorityColor, size: 20),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            
            // Row 2: Title
            Text(
              task.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: AppSizes.xs),
            
            // Row 3: Description preview
            Text(
              task.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey600),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Divider(height: 1),
            ),

            // Row 4: Metadata (Date, Comments, Attachments, Avatar)
            Row(
              children: [
                if (task.deadline != null) ...[
                  Icon(
                    Icons.calendar_today_rounded, 
                    size: 14, 
                    color: task.deadline!.isOverdue ? AppColors.error : AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.deadline!.shortDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.deadline!.isOverdue ? AppColors.error : AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                ],
                
                if (commentCount > 0) ...[
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text('$commentCount', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
                  const SizedBox(width: AppSizes.sm),
                ],

                if (attachmentCount > 0) ...[
                  const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 2),
                  Text('$attachmentCount', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
                ],

                const Spacer(),
                
                // Avatar Group
                SizedBox(
                  width: 30,
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundImage: NetworkImage(assignee.avatarUrl!),
                          ),
                        ),
                      ),
                      // If there is a reporter/reviewer, we could stack it here
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().slideY(begin: 0.05, delay: (50 * index).ms, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
    );
  }
}
