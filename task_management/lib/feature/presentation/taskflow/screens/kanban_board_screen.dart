import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/task_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';
import 'task_detail_screen.dart';
import 'create_task_sheet.dart';
import 'invite_member_dialog.dart';

/// Kanban board — redesigned UI from `TaskFlow.dc.html` (03 — Tasks), wired to
/// the task provider (tasks grouped into status columns).
class KanbanBoardScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const KanbanBoardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.workspaceId = '',
    this.workspaceName = '',
  });

  static const _columns = [
    TaskStatus.todo,
    TaskStatus.doing,
    TaskStatus.review,
    TaskStatus.done,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final state = ref.watch(taskNotifierProvider(projectId));
    final tasks = state.tasks;

    return Scaffold(
      backgroundColor: p.surface2,
      floatingActionButton: GestureDetector(
        onTap: () => showCreateTaskSheet(context, projectId: projectId),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: p.accent.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 28, color: p.onAccent),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_rounded, size: 22, color: p.text2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(projectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: p.text)),
                        Text('Board · ${tasks.length} tasks',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: p.text3)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showInviteMemberDialog(
                      context,
                      projectId: projectId,
                      workspaceId: workspaceId,
                      workspaceName: workspaceName,
                    ),
                    child: Icon(Icons.group_add_rounded, size: 22, color: p.text2),
                  ),
                ],
              ),
            ),
            // ── Board ───────────────────────────────────────────────────
            Expanded(child: _boardBody(context, ref, state, tasks)),
          ],
        ),
      ),
    );
  }

  Widget _boardBody(
      BuildContext context, WidgetRef ref, TaskState state, List<TaskEntity> tasks) {
    if (state.isLoading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && tasks.isEmpty) {
      return _Message(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load tasks',
          subtitle: state.error!);
    }
    if (tasks.isEmpty) {
      return _Message(
          icon: Icons.checklist_rounded,
          title: 'No tasks yet',
          subtitle: 'Tap the + button to add the first task.');
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      children: [
        for (final status in _columns)
          _Column(
            status: status,
            tasks: tasks.where((t) => t.status == status).toList(),
          ),
      ],
    );
  }
}

class _Column extends ConsumerWidget {
  final TaskStatus status;
  final List<TaskEntity> tasks;
  const _Column({required this.status, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TfStatusDot(color: statusColor(p, status), size: 8),
              const SizedBox(width: 8),
              Text(statusLabel(status),
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                    color: p.surface3, borderRadius: BorderRadius.circular(999)),
                child: Text('${tasks.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.text3)),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Expanded(
            child: tasks.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _BoardCard(task: tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final TaskEntity task;
  const _BoardCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final highlighted = task.status == TaskStatus.doing;
    final done = task.status == TaskStatus.done;
    return TfCard(
      radius: 15,
      padding: const EdgeInsets.all(13),
      border: Border.all(color: highlighted ? p.accent : p.border),
      shadow: highlighted
          ? [
              BoxShadow(
                  color: p.accent.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -12)
            ]
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TfTag(
              text: priorityLabel(task.priority),
              color: priorityColor(p, task.priority)),
          const SizedBox(height: 9),
          Text(task.title,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? p.text3 : p.text)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (task.deadline != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_rounded, size: 15, color: p.text3),
                    const SizedBox(width: 3),
                    Text(DateFormat('MMM d').format(task.deadline!),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.text3)),
                  ],
                )
              else
                const SizedBox.shrink(),
              if ((task.assigneeName ?? '').isNotEmpty)
                TfAvatar(
                  initials: initialsOf(task.assigneeName),
                  color: avatarColorFor(task.assigneeId ?? task.assigneeName!),
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Message(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: p.text3),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: p.text3)),
          ],
        ),
      ),
    );
  }
}
