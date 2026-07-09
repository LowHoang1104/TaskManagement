import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/task_detail_provider.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskEntity task;
  
  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskState = ref.watch(taskDetailProvider(widget.task));
    final task = taskState.task;
    final notifier = ref.read(taskDetailProvider(widget.task).notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white), 
                    onPressed: () => _showEditTaskDialog(context, task, notifier),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content: const Text('This will permanently delete the task and its comments/attachments. Are you sure?'),
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
                          final success = await ref.read(taskNotifierProvider(task.projectId).notifier).deleteTask(task.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted.')));
                            Navigator.pop(context); // Go back to Kanban board
                          } else if (context.mounted) {
                            final error = ref.read(taskNotifierProvider(task.projectId)).error;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete task')));
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
                    ],
                  ),
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
                            colors: [Color(0xFFD1FAE5), Color(0xFFFEF3C7)],
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
                          Text('TaskFlow', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.grey400),
                          const SizedBox(width: 8),
                          Text(task.id.substring(0, 8).toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600)),
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
                        children: [], // Add tags later
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: AppSizes.xl),

                      // Grid Metadata
                      Container(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildGridRow('Assignee', const Text('Unassigned'), 'Reporter', const Text('Reporter'), theme),
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
                      if (taskState.attachments.isNotEmpty) ...[
                        Text('Attachments (${taskState.attachments.length})', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: AppSizes.xs),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: taskState.attachments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                            itemBuilder: (context, index) {
                              final attachment = taskState.attachments[index];
                              final kbSize = (attachment.fileSize / 1024).toStringAsFixed(1);
                              return _buildAttachmentCard(attachment.fileName, '$kbSize KB', Icons.insert_drive_file, AppColors.primary);
                            },
                          ),
                        ).animate().slideX(begin: 0.1, delay: 400.ms).fadeIn(),
                        const SizedBox(height: AppSizes.xxl),
                      ],

                      // Activity / Comments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Activity', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 500.ms),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      
                      if (taskState.isLoading && taskState.comments.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (taskState.comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No comments yet.', style: TextStyle(color: AppColors.grey400)),
                        )
                      else
                        ...taskState.comments.map((comment) => _buildCommentItem(comment, theme)).toList(),

                      const SizedBox(height: 100), // Space for bottom input
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
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18, 
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: const TextStyle(color: AppColors.grey400),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                              ),onSubmitted: (value) {
                              notifier.addComment(value);
                              _commentController.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: () {
                            notifier.addComment(_commentController.text);
                            _commentController.clear();
                          },
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
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

  Widget _buildCommentItem(CommentEntity comment, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surface,
            child: const Icon(Icons.person, color: AppColors.grey600, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userFullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('commented', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey600)),
                    const Spacer(),
                    Text('Just now', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey400)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd).copyWith(topLeft: Radius.zero),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(comment.content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskEntity task, TaskDetailNotifier notifier) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedPriority = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    notifier.updateTask(task.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      priority: selectedPriority,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
