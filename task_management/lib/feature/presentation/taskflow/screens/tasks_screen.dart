import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../taskflow_providers.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';
import 'task_detail_screen.dart';

/// My Tasks (list) — redesigned UI from `TaskFlow.dc.html` (03 — Tasks), wired
/// to [myTasksProvider] (the current user's tasks across the workspace,
/// bucketed by deadline into Today / Upcoming / Overdue).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

enum _Bucket { today, upcoming, overdue }

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Bucket _filter = _Bucket.today;

  _Bucket _bucketOf(TaskWithProject t) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final endToday = startToday.add(const Duration(days: 1));
    final d = t.task.deadline;
    final done = t.task.status == TaskStatus.done;
    if (d != null && d.isBefore(startToday) && !done) return _Bucket.overdue;
    if (d != null && !d.isBefore(endToday)) return _Bucket.upcoming;
    return _Bucket.today;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final workspace = ref.watch(currentWorkspaceProvider);

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          color: p.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Tasks',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: p.text)),
                  Icon(Icons.filter_list_rounded, size: 24, color: p.text2),
                ],
              ),
              const SizedBox(height: 13),
              if (workspace != null)
                Consumer(builder: (context, ref, _) {
                  final async = ref.watch(myTasksProvider(workspace.id));
                  final all = async.valueOrNull ?? const <TaskWithProject>[];
                  final counts = <_Bucket, int>{
                    for (final b in _Bucket.values)
                      b: all.where((t) => _bucketOf(t) == b).length
                  };
                  return Row(
                    children: [
                      TfPill(
                          label: 'Today · ${counts[_Bucket.today]}',
                          selected: _filter == _Bucket.today,
                          onTap: () => setState(() => _filter = _Bucket.today)),
                      const SizedBox(width: 8),
                      TfPill(
                          label: 'Upcoming · ${counts[_Bucket.upcoming]}',
                          selected: _filter == _Bucket.upcoming,
                          onTap: () =>
                              setState(() => _filter = _Bucket.upcoming)),
                      const SizedBox(width: 8),
                      TfPill(
                          label: 'Overdue · ${counts[_Bucket.overdue]}',
                          tone: p.danger,
                          selected: _filter == _Bucket.overdue,
                          onTap: () =>
                              setState(() => _filter = _Bucket.overdue)),
                    ],
                  );
                }),
            ],
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: p.surface2,
            child: workspace == null
                ? _message(context,
                    icon: Icons.checklist_rounded,
                    title: 'No workspace',
                    subtitle: 'Create a workspace and projects to see your tasks.')
                : _body(context, workspace.id),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, String workspaceId) {
    final async = ref.watch(myTasksProvider(workspaceId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _message(context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load tasks',
          subtitle: '$e'),
      data: (all) {
        final items = all.where((t) => _bucketOf(t) == _filter).toList()
          ..sort((a, b) {
            final da = a.task.deadline;
            final db = b.task.deadline;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
        if (items.isEmpty) {
          return _message(context,
              icon: Icons.task_alt_rounded,
              title: 'Nothing here',
              subtitle: 'No tasks in this view. Enjoy the calm.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myTasksProvider(workspaceId)),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TaskRow(
              item: items[i],
              overdue: _filter == _Bucket.overdue,
              onToggle: () => _toggleDone(workspaceId, items[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleDone(String workspaceId, TaskWithProject item) async {
    final task = item.task;
    final next =
        task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;

    // Must await: [myTasksProvider] re-reads from the server, so invalidating
    // before the PUT lands would refetch the old status and flip the tick back.
    await ref
        .read(taskNotifierProvider(task.projectId).notifier)
        .updateTaskStatusLocally(task.id, next);
    if (!mounted) return;

    final error = ref.read(taskNotifierProvider(task.projectId)).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.palette.danger),
      );
      return;
    }

    ref.invalidate(myTasksProvider(workspaceId));
    // Completing a task changes the project's "3 / 14 tasks" progress too.
    ref.invalidate(projectNotifierProvider(workspaceId));
  }

  Widget _message(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    final p = context.palette;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: p.text3),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text3)),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskWithProject item;
  final bool overdue;
  final VoidCallback onToggle;
  const _TaskRow(
      {required this.item, required this.overdue, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final task = item.task;
    final done = task.status == TaskStatus.done;
    return TfCard(
      radius: 15,
      padding: const EdgeInsets.all(13),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: done ? p.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: done ? null : Border.all(color: p.border2, width: 2),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 15, color: p.onAccent)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? p.text3 : p.text)),
                const SizedBox(height: 8),
                _meta(context),
              ],
            ),
          ),
          if (priorityColor(p, task.priority) != null) ...[
            const SizedBox(width: 8),
            TfTag(
                text: priorityLabel(task.priority),
                color: priorityColor(p, task.priority)),
          ],
        ],
      ),
    );
  }

  Widget _meta(BuildContext context) {
    final p = context.palette;
    final task = item.task;
    if (overdue && task.deadline != null) {
      return Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Overdue · ${DateFormat('MMM d').format(task.deadline!)}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: p.danger)),
          const SizedBox(width: 6),
          Flexible(
            child: Text('· ${item.projectName}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: p.text3)),
          ),
        ],
      );
    }
    final statusC = statusColor(p, task.status);
    return Row(
      children: [
        Text(statusLabel(task.status),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: task.status == TaskStatus.doing ? p.accent : statusC)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
              '· ${item.projectName}${task.deadline != null ? ' · ${DateFormat('MMM d').format(task.deadline!)}' : ''}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: p.text3)),
        ),
      ],
    );
  }
}
