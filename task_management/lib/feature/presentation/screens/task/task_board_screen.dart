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
import '../../providers/project_members_provider.dart';
import '../../providers/task_dependencies_provider.dart';
import '../notification/notification_screen.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final String workspaceName;
  final String workspaceId;
  
  const TaskBoardScreen({super.key, required this.projectId, required this.projectName, required this.workspaceName, required this.workspaceId});

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
                    Navigator.pushNamed(context, AppRoutes.projectMembers, arguments: {
                      'projectId': widget.projectId,
                      'workspaceId': widget.workspaceId,
                    });
                  },
                ),
                const SizedBox(width: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light 
                ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), const Color(0xFFE0E7FF)]
                : [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF312E81)],
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }

  Widget _buildColumn(TaskStatus status, String title, Color color, ThemeData theme, List<TaskEntity> allTasks) {
    final tasks = allTasks.where((t) => t.status == status).toList();

    return DragTarget<TaskEntity>(
      onAcceptWithDetails: (details) async {
        if (details.data.status != status) {
          final task = details.data;
          
          final errorMsg = _validateTaskMove(task, status, allTasks, ref);

          if (errorMsg != null) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(errorMsg, style: const TextStyle(color: Colors.white)), 
                 backgroundColor: Colors.red.shade800,
                 behavior: SnackBarBehavior.floating,
             ));
             return; // Stop update
          }
          
          if (task.status == TaskStatus.done && status != TaskStatus.done) {
             final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                   title: const Text('Revert Task?'),
                   content: const Text('Are you sure you want to pull this task back from Done?'),
                   actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm', style: TextStyle(color: Colors.orange))),
                   ],
                ),
             );
             if (confirm != true) return;
          }

          ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskStatusLocally(details.data.id, status);

          // Auto-assign if unassigned
          final currentUser = ref.read(authNotifierProvider).user;
          if (task.assigneeId == null && currentUser != null) {
            ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskAssignee(task.id, currentUser.id);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(left: 12, top: AppSizes.md, bottom: AppSizes.xl, right: 4),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? color.withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: candidateData.isNotEmpty ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lens, size: 10, color: color),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${tasks.length}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    if (status == TaskStatus.todo)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.add_rounded, size: 20, color: color),
                        onPressed: () => _showCreateTaskDialog(context, ref, theme, status),
                      )
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
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

  String? _validateTaskMove(TaskEntity task, TaskStatus status, List<TaskEntity> allTasks, WidgetRef ref) {
    for (final dep in task.dependencies) {
       try {
          final predecessor = allTasks.firstWhere((t) => t.id == dep.predecessorTaskId);
          
          if (dep.dependencyType == 'FS') {
             if (status != TaskStatus.todo && predecessor.status != TaskStatus.done) {
                return 'Cannot start until "${predecessor.title}" is done (FS).';
             }
          } else if (dep.dependencyType == 'SS') {
             if (status != TaskStatus.todo && predecessor.status == TaskStatus.todo) {
                return 'Cannot start until "${predecessor.title}" has started (SS).';
             }
          } else if (dep.dependencyType == 'FF') {
             if (status == TaskStatus.done && predecessor.status != TaskStatus.done) {
                return 'Cannot finish until "${predecessor.title}" is done (FF).';
             }
          } else if (dep.dependencyType == 'SF') {
             if (status == TaskStatus.done && predecessor.status == TaskStatus.todo) {
                return 'Cannot finish until "${predecessor.title}" has started (SF).';
             }
          }
       } catch (e) {
          // Ignore
       }
    }
    
    final projectMembersState = ref.read(projectMembersProvider(widget.projectId));
    final currentUser = ref.read(authNotifierProvider).user;
    final currentMember = projectMembersState.members.where((m) => m.id == currentUser?.id).firstOrNull;
    final isOwnerOrAdmin = currentMember != null && (currentMember.role == 'Owner' || currentMember.role == 'Admin');

    if (task.assigneeId != null && task.assigneeId != currentUser?.id && !isOwnerOrAdmin) {
       return 'Only the assigned member or project Admins/Owners can move this task.';
    }
    
    if (status == TaskStatus.done && !isOwnerOrAdmin) {
      return 'Only project Admins or Owners can mark a task as Done.';
    }

    if (task.status == TaskStatus.done && status != TaskStatus.done && !isOwnerOrAdmin) {
      return 'Only project Admins or Owners can pull a task back from Done.';
    }

    return null; // Valid
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref, ThemeData theme, TaskStatus initialStatus) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;
    
    // Dependencies state for creation
    final projectTasks = ref.read(taskNotifierProvider(widget.projectId)).tasks;
    String? selectedPredecessorId;
    String selectedDependencyType = 'FS';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      items: TaskPriority.values.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedPriority = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Dependencies (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedPredecessorId,
                      decoration: const InputDecoration(labelText: 'Task to depend on'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ...projectTasks.map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ))
                      ],
                      onChanged: (v) => setState(() => selectedPredecessorId = v),
                    ),
                    if (selectedPredecessorId != null) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedDependencyType,
                        decoration: const InputDecoration(labelText: 'Dependency Type'),
                        items: const [
                          DropdownMenuItem(value: 'FS', child: Text('Finish to Start (FS)')),
                          DropdownMenuItem(value: 'SS', child: Text('Start to Start (SS)')),
                          DropdownMenuItem(value: 'FF', child: Text('Finish to Finish (FF)')),
                          DropdownMenuItem(value: 'SF', child: Text('Start to Finish (SF)')),
                        ],
                        onChanged: (v) => setState(() => selectedDependencyType = v!),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isNotEmpty) {
                      // 1. Create Task
                      final newTask = await ref.read(taskNotifierProvider(widget.projectId).notifier)
                          .createTask(titleController.text.trim(), descController.text.trim(), initialStatus, selectedPriority);
                      
                      if (newTask != null && selectedPredecessorId != null) {
                        // 2. Assign dependency
                        await ref.read(taskDependenciesProvider(newTask.id).notifier)
                            .setDependency(selectedPredecessorId!, selectedDependencyType);
                            
                        // Refresh the board tasks to get the new dependencies
                        ref.read(taskNotifierProvider(widget.projectId).notifier).fetchTasks();
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
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
    Color priorityColor = AppColors.info;
    IconData priorityIcon = Icons.keyboard_arrow_down_rounded;
    if (task.priority == TaskPriority.high) {
      priorityColor = Colors.orange;
      priorityIcon = Icons.keyboard_arrow_up_rounded;
    }
    if (task.priority == TaskPriority.critical) {
      priorityColor = AppColors.error;
      priorityIcon = Icons.keyboard_double_arrow_up_rounded;
    }
    
    Color statusColor = AppColors.grey400;
    if (task.status == TaskStatus.doing) statusColor = Colors.blue;
    if (task.status == TaskStatus.review) statusColor = Colors.orange;
    if (task.status == TaskStatus.done) statusColor = Colors.green;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.taskDetail, arguments: task).then((_) {
          ref.read(taskNotifierProvider(widget.projectId).notifier).fetchTasks();
        });
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light ? AppColors.grey400.withValues(alpha: 0.2) : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                               color: priorityColor.withValues(alpha: 0.15),
                               borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(priorityIcon, size: 12, color: priorityColor),
                                const SizedBox(width: 4),
                                Text(task.priority.name.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor)),
                              ]
                            )
                          ),
                          if (task.deadline != null && task.deadline!.isOverdue)
                             const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (task.deadline != null) ...[
                            Icon(
                              Icons.calendar_today_rounded, 
                              size: 12, 
                              color: task.deadline!.isOverdue ? AppColors.error : AppColors.grey400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.deadline!.day}/${task.deadline!.month}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: task.deadline!.isOverdue ? AppColors.error : AppColors.grey600,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (task.assigneeId != null)
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                task.assigneeName != null && task.assigneeName!.isNotEmpty ? task.assigneeName![0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const CircleAvatar(
                               radius: 10,
                               backgroundColor: AppColors.grey200,
                               child: Icon(Icons.person_outline, size: 12, color: AppColors.grey600),
                            ),
                          const Spacer(),
                          if (task.status != TaskStatus.todo)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              color: AppColors.grey400,
                              onPressed: () {
                                TaskStatus? prevStatus;
                                switch (task.status) {
                                  case TaskStatus.todo: break;
                                  case TaskStatus.doing: prevStatus = TaskStatus.todo; break;
                                  case TaskStatus.review: prevStatus = TaskStatus.doing; break;
                                  case TaskStatus.done: prevStatus = TaskStatus.review; break;
                                }
                                if (prevStatus != null) {
                                  final allTasks = ref.read(taskNotifierProvider(widget.projectId)).tasks;
                                  final errorMsg = _validateTaskMove(task, prevStatus, allTasks, ref);
                                  if (errorMsg != null) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red.shade800));
                                     return;
                                  }
                                  ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskStatusLocally(task.id, prevStatus);
                                }
                              },
                            ),
                          if (task.status != TaskStatus.done)
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              color: statusColor != AppColors.grey400 ? statusColor : AppColors.primary,
                              onPressed: () {
                                TaskStatus? nextStatus;
                                switch (task.status) {
                                  case TaskStatus.todo: nextStatus = TaskStatus.doing; break;
                                  case TaskStatus.doing: nextStatus = TaskStatus.review; break;
                                  case TaskStatus.review: nextStatus = TaskStatus.done; break;
                                  case TaskStatus.done: break;
                                }
                                if (nextStatus != null) {
                                  final allTasks = ref.read(taskNotifierProvider(widget.projectId)).tasks;
                                  final errorMsg = _validateTaskMove(task, nextStatus, allTasks, ref);
                                  if (errorMsg != null) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red.shade800));
                                     return;
                                  }
                                  ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskStatusLocally(task.id, nextStatus);
                                  final currentUser = ref.read(authNotifierProvider).user;
                                  if (task.assigneeId == null && currentUser != null) {
                                    ref.read(taskNotifierProvider(widget.projectId).notifier).updateTaskAssignee(task.id, currentUser.id);
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.05, delay: (50 * index).ms, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
    );
  }
}
