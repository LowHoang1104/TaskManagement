import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../notification/notification_screen.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final String workspaceName;
  
  const TaskBoardScreen({super.key, required this.projectId, required this.projectName, required this.workspaceName});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskState = ref.watch(taskNotifierProvider(widget.projectId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
              elevation: 0,
              iconTheme: IconThemeData(color: theme.iconTheme.color),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.projectName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.workspaceName,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(notificationProvider).unreadCount;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded, color: theme.iconTheme.color),
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
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                  icon: Icon(Icons.people_outline_rounded, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.projectMembers, arguments: widget.projectId);
                  },
                ),
                IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {}),
                const SizedBox(width: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: taskState.isLoading && taskState.tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: PageController(viewportFraction: 0.88),
                padEnds: false,
                children: [
                  _buildColumn(TaskStatus.todo, 'CẦN LÀM', AppColors.grey600, theme, taskState.tasks),
                  _buildColumn(TaskStatus.doing, 'ĐANG TIẾN HÀNH', Colors.blue, theme, taskState.tasks),
                  _buildColumn(TaskStatus.review, 'CHỜ DUYỆT', Colors.orange, theme, taskState.tasks),
                  _buildColumn(TaskStatus.done, 'HOÀN THÀNH', Colors.green, theme, taskState.tasks),
                ],
              ),
      ),
    );
  }

  Widget _buildColumn(TaskStatus status, String title, Color color, ThemeData theme, List<TaskEntity> allTasks) {
    final tasks = allTasks.where((t) => t.status == status).toList();

    return DragTarget<TaskEntity>(
      onAcceptWithDetails: (details) {
        if (details.data.status != status) {
          ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskStatusLocally(details.data.id, status);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(left: AppSizes.lg, top: AppSizes.md, bottom: AppSizes.xl, right: 8),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? color.withValues(alpha: 0.1) 
                : (theme.brightness == Brightness.light ? AppColors.grey200.withValues(alpha: 0.5) : AppColors.grey800.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: candidateData.isNotEmpty ? color : theme.colorScheme.surface, width: 2),
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
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${tasks.length}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    onPressed: () => _showCreateTaskDialog(context, ref, theme, status),
                  )
                ],
              ),
              const SizedBox(height: AppSizes.md),
              // Task List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(taskNotifierProvider(widget.projectId).notifier).fetchTasks();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return LongPressDraggable<TaskEntity>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.8,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: _buildPremiumTaskCard(task, theme, index),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildPremiumTaskCard(task, theme, index),
                        ),
                        child: _buildPremiumTaskCard(task, theme, index),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref, ThemeData theme, TaskStatus initialStatus) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Task'),
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
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      ref.read(taskNotifierProvider(widget.projectId).notifier).createTask(
                        titleController.text.trim(),
                        descController.text.trim(),
                        initialStatus,
                        selectedPriority,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      },
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

    final commentCount = 0; // Replace with actual API later
    final attachmentCount = 0; // Replace with actual API later

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.taskDetail, arguments: task);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light ? AppColors.grey400.withValues(alpha: 0.5) : Colors.black26,
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
                    children: [], // Add actual tags later
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
                if (task.assigneeId != null)
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
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
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
