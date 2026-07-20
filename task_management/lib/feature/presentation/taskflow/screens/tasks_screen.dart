import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/workspace_provider.dart';
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

enum _Bucket { today, upcoming, overdue, done }

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Bucket _filter = _Bucket.today;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Extra filters (from the funnel icon). null = "any".
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _projectFilter; // project id

  bool get _hasExtraFilters =>
      _statusFilter != null ||
      _priorityFilter != null ||
      _projectFilter != null;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _Bucket _bucketOf(TaskWithProject t) {
    // Completed tasks live in their own bucket, never mixed into the
    // deadline-based buckets (a done task isn't "due today").
    if (t.task.status == TaskStatus.done) return _Bucket.done;
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final endToday = startToday.add(const Duration(days: 1));
    final d = t.task.deadline;
    if (d != null && d.isBefore(startToday)) return _Bucket.overdue;
    if (d != null && !d.isBefore(endToday)) return _Bucket.upcoming;
    return _Bucket.today;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasWorkspace =
        ref.watch(workspaceNotifierProvider).workspaces.isNotEmpty;
    final searching = _query.trim().isNotEmpty;

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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openFilterSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.filter_list_rounded,
                            size: 24,
                            color: _hasExtraFilters ? p.accent : p.text2),
                        if (_hasExtraFilters)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.surface, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _searchField(p),
              const SizedBox(height: 12),
              if (hasWorkspace && !searching)
                Consumer(builder: (context, ref, _) {
                  final async = ref.watch(allMyTasksProvider);
                  final all = async.valueOrNull ?? const <TaskWithProject>[];
                  final counts = <_Bucket, int>{
                    for (final b in _Bucket.values)
                      b: all.where((t) => _bucketOf(t) == b).length
                  };
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TfPill(
                            label: 'Today · ${counts[_Bucket.today]}',
                            selected: _filter == _Bucket.today,
                            onTap: () =>
                                setState(() => _filter = _Bucket.today)),
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
                        const SizedBox(width: 8),
                        TfPill(
                            label: 'Done · ${counts[_Bucket.done]}',
                            tone: p.success,
                            selected: _filter == _Bucket.done,
                            onTap: () =>
                                setState(() => _filter = _Bucket.done)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: p.surface2,
            child: !hasWorkspace
                ? _message(context,
                    icon: Icons.checklist_rounded,
                    title: 'No workspace',
                    subtitle: 'Create a workspace and projects to see your tasks.')
                : _body(context),
          ),
        ),
      ],
    );
  }

  /// Bottom sheet to filter the list by status and/or priority. Applies on top
  /// of the bucket pills and the search box.
  void _openFilterSheet() {
    final p = context.palette;
    // Work on local copies so the sheet's own state drives the chips; only
    // commit back to the screen when the user taps "Apply".
    var status = _statusFilter;
    var priority = _priorityFilter;
    var projectId = _projectFilter;

    // Distinct projects present in the loaded tasks (id → name), sorted by name.
    final loaded = ref.read(allMyTasksProvider).valueOrNull ??
        const <TaskWithProject>[];
    final projects = <String, String>{};
    for (final t in loaded) {
      projects[t.task.projectId] = t.projectName;
    }
    final projectEntries = projects.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Widget chip(String label, bool selected, VoidCallback onTap,
                {Color? tone}) {
              final c = tone ?? p.accent;
              return GestureDetector(
                onTap: () => setSheetState(onTap),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? c : p.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? c : p.border),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? p.onAccent : p.text2)),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.surface3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Filters',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                  const SizedBox(height: 16),
                  Text('Status',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.text2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('All', status == null,
                          () => status = null),
                      for (final s in TaskStatus.values)
                        chip(statusLabel(s), status == s,
                            () => status = status == s ? null : s),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Priority',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.text2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('All', priority == null,
                          () => priority = null),
                      for (final pr in TaskPriority.values)
                        chip(priorityLabel(pr), priority == pr,
                            () => priority = priority == pr ? null : pr),
                    ],
                  ),
                  if (projectEntries.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Project',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.text2)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip('All', projectId == null,
                            () => projectId = null),
                        for (final e in projectEntries)
                          chip(e.value, projectId == e.key,
                              () => projectId =
                                  projectId == e.key ? null : e.key),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setSheetState(() {
                            status = null;
                            priority = null;
                            projectId = null;
                          }),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: p.border),
                            ),
                          ),
                          child: Text('Clear',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: p.text2)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = status;
                              _priorityFilter = priority;
                              _projectFilter = projectId;
                            });
                            Navigator.pop(sheetCtx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _searchField(AppPalette p) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(fontSize: 13.5, color: p.text),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search all tasks…',
        hintStyle: TextStyle(fontSize: 13.5, color: p.text3),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.text3),
        suffixIcon: _query.isEmpty
            ? null
            : GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Icon(Icons.close_rounded, size: 18, color: p.text3),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        filled: true,
        fillColor: p.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final async = ref.watch(allMyTasksProvider);
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _message(context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load tasks',
          subtitle: '$e'),
      data: (all) {
        // When searching, look across every bucket by title/project name.
        // Otherwise show the tasks that fall into the selected bucket.
        // The status/priority filters (funnel icon) apply on top of both.
        final items =
            all.where((t) {
              if (_statusFilter != null && t.task.status != _statusFilter) {
                return false;
              }
              if (_priorityFilter != null &&
                  t.task.priority != _priorityFilter) {
                return false;
              }
              if (_projectFilter != null &&
                  t.task.projectId != _projectFilter) {
                return false;
              }
              if (searching) {
                return t.task.title.toLowerCase().contains(q) ||
                    t.projectName.toLowerCase().contains(q);
              }
              return _bucketOf(t) == _filter;
            }).toList()
              ..sort((a, b) {
                final da = a.task.deadline;
                final db = b.task.deadline;
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return da.compareTo(db);
              });
        if (items.isEmpty) {
          final filtered = searching || _hasExtraFilters;
          return _message(context,
              icon: filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
              title: filtered ? 'No matches' : 'Nothing here',
              subtitle: searching
                  ? 'No tasks match "${_query.trim()}".'
                  : _hasExtraFilters
                      ? 'No tasks match the selected filters.'
                      : 'No tasks in this view. Enjoy the calm.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allMyTasksProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TaskRow(
              item: items[i],
              overdue: !searching && _filter == _Bucket.overdue,
              onToggle: () => _toggleDone(items[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleDone(TaskWithProject item) async {
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

    ref.invalidate(myTasksProvider(item.workspaceId));
    ref.invalidate(allMyTasksProvider);
    // Completing a task changes the project's "3 / 14 tasks" progress too.
    ref.invalidate(projectNotifierProvider(item.workspaceId));
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
