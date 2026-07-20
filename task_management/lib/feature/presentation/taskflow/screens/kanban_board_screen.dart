import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/task_provider.dart';
import '../taskflow_providers.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';
import 'task_detail_screen.dart';
import 'create_task_sheet.dart';
import 'invite_member_dialog.dart';
import '../../providers/auth_provider.dart';

/// How the cards inside each status column are ordered.
enum _BoardSort { deadline, created, priority, title }

extension _BoardSortX on _BoardSort {
  String get label => switch (this) {
    _BoardSort.deadline => 'Deadline',
    _BoardSort.created => 'Ngày tạo',
    _BoardSort.priority => 'Độ ưu tiên',
    _BoardSort.title => 'Tên (A–Z)',
  };

  IconData get icon => switch (this) {
    _BoardSort.deadline => Icons.event_rounded,
    _BoardSort.created => Icons.schedule_rounded,
    _BoardSort.priority => Icons.flag_rounded,
    _BoardSort.title => Icons.sort_by_alpha_rounded,
  };

  /// Returns a new sorted list; the input is not mutated.
  List<TaskEntity> apply(List<TaskEntity> tasks) {
    final sorted = [...tasks];
    switch (this) {
      case _BoardSort.deadline:
        // Soonest deadline first; tasks with no deadline sink to the bottom.
        sorted.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
      case _BoardSort.created:
        // Newest first.
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _BoardSort.priority:
        // Highest priority first (critical → low).
        sorted.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case _BoardSort.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sorted;
  }
}

/// Kanban board — redesigned UI from `TaskFlow.dc.html` (03 — Tasks), wired to
/// the task provider (tasks grouped into status columns).
class KanbanBoardScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  static const _columns = [
    TaskStatus.todo,
    TaskStatus.doing,
    TaskStatus.review,
    TaskStatus.done,
  ];

  _BoardSort _sort = _BoardSort.deadline;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(taskNotifierProvider(widget.projectId));
    final tasks = state.tasks;
    // Only Owner/Admin can create tasks — hide the button for members.
    final canManage = ref.watch(canManageProjectProvider(widget.projectId));

    return Scaffold(
      backgroundColor: p.surface2,
      floatingActionButton: !canManage
          ? null
          : GestureDetector(
              onTap: () =>
                  showCreateTaskSheet(context, projectId: widget.projectId),
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
                        Text(widget.projectName,
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
                  _sortButton(p),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => showInviteMemberDialog(
                      context,
                      projectId: widget.projectId,
                      workspaceId: widget.workspaceId,
                      workspaceName: widget.workspaceName,
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

  /// Popup menu to pick how each column's cards are ordered.
  Widget _sortButton(AppPalette p) {
    return PopupMenuButton<_BoardSort>(
      tooltip: 'Sắp xếp',
      initialValue: _sort,
      onSelected: (v) => setState(() => _sort = v),
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      itemBuilder: (_) => [
        for (final s in _BoardSort.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(s.icon, size: 17, color: p.text2),
                const SizedBox(width: 10),
                Text(s.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.text)),
                if (s == _sort) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 16, color: p.accent),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16, color: p.text2),
            const SizedBox(width: 4),
            Text(_sort.label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.text2)),
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
            tasks: _sort.apply(
              tasks.where((t) => t.status == status).toList(),
            ),
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

class _BoardCard extends ConsumerWidget {
  final TaskEntity task;
  const _BoardCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = ref.watch(authNotifierProvider).user;
    final isMine = task.assigneeId == me?.id && me?.id != null;
    
    final highlighted = task.status == TaskStatus.doing;
    final done = task.status == TaskStatus.done;
    
    return TfCard(
      radius: 15,
      padding: const EdgeInsets.all(13),
      color: isMine ? (isDark ? p.surface2 : p.surface.withAlpha(220)) : null,
      border: Border.all(color: highlighted ? p.accent : (isMine ? p.accent.withAlpha(150) : p.border)),
      shadow: highlighted
          ? [
              BoxShadow(
                  color: p.accent.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -12)
            ]
          : (isMine 
              ? [BoxShadow(color: p.accent.withValues(alpha: 0.1), blurRadius: 10)] 
              : null),
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
