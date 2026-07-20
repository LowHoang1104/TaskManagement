import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../domain/entities/comment_entity.dart';
import '../../../domain/entities/attachment_entity.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/entities/task_relation_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_members_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_detail_provider.dart';
import '../../providers/task_provider.dart';
import '../taskflow_providers.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Task detail — redesigned UI from `TaskFlow.dc.html` (03 — Tasks), wired to
/// `taskDetailProvider` (live comments, attachments, add-comment).
class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskEntity task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _starred = false;
  bool _sending = false;
  bool _uploading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await ref.read(taskDetailProvider(widget.task).notifier).addComment(text);
    _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }

  /// Move the task between statuses (To Do → In Progress → Review → Done).
  ///
  /// Permission rules:
  /// - Members may move a task among To Do / In Progress / Review.
  /// - Only Owner/Admin can set a task to **Done**.
  /// - A task that is already Done is locked for members.
  void _pickStatus() {
    final p = context.palette;
    final canManage = _canManage();
    final current = ref.read(taskDetailProvider(widget.task)).task.status;

    // A completed task is locked: members can no longer change it.
    if (current == TaskStatus.done && !canManage) {
      _denied('change a task that is already Done');
      return;
    }

    // Members can move To Do → In Progress → Review, but not to Done.
    final options = canManage
        ? TaskStatus.values
        : const [TaskStatus.todo, TaskStatus.doing, TaskStatus.review];

    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 14),
            Text(
              'Move task to',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            if (!canManage) ...[
              const SizedBox(height: 4),
              Text(
                'Only Owner/Admin can move a task to Done.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.text3,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final s in options)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (s == current) return;
                  await ref
                      .read(taskDetailProvider(widget.task).notifier)
                      .updateStatus(s, ref);
                  if (!mounted) return;
                  // Surface backend rejections (permissions / dependency block).
                  final error = ref.read(taskDetailProvider(widget.task)).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: p.danger),
                    );
                    return;
                  }
                  // Status drives the project's "3 / 14 tasks" progress and the
                  // My Tasks buckets — refresh both.
                  ref.invalidate(projectNotifierProvider);
                  ref.invalidate(myTasksProvider);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      TfStatusDot(color: statusColor(p, s)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusLabel(s),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                      ),
                      if (s == current)
                        Icon(Icons.check_rounded, size: 20, color: p.accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// True when the signed-in user is Owner/Admin of this task's project.
  /// Only they may assign a task or set/edit its deadline (the API enforces
  /// this too — members get a 403).
  bool _canManage() {
    final me = ref.read(authNotifierProvider).user;
    final members = ref
        .read(projectMembersProvider(widget.task.projectId))
        .members;
    final myRole = members
        .where((m) => m.id == me?.id)
        .map((m) => m.role)
        .firstOrNull;
    return myRole == 'Owner' || myRole == 'Admin';
  }

  void _denied(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Only Owner/Admin can $what.'),
        backgroundColor: context.palette.text2,
      ),
    );
  }

  /// Pick a date + time for the deadline (Owner/Admin only).
  Future<void> _pickDeadline() async {
    if (!_canManage()) {
      _denied('change the deadline');
      return;
    }

    final current = ref.read(taskDetailProvider(widget.task)).task.deadline;
    final now = DateTime.now();
    final base = current ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (!mounted) return;

    final deadline = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 17,
      time?.minute ?? 0,
    );

    await ref
        .read(taskDetailProvider(widget.task).notifier)
        .updateDeadline(deadline, ref);
    if (!mounted) return;

    final error = ref.read(taskDetailProvider(widget.task)).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.palette.danger),
      );
      return;
    }
    // Deadline drives the Today / Upcoming / Overdue buckets.
    ref.invalidate(myTasksProvider);
  }

  /// Applies the assignee change using the screen's `ref` (safe after the
  /// picker sheet is popped) and refreshes the views that show the assignee.
  Future<void> _assign(String? assigneeId) async {
    await ref
        .read(taskDetailProvider(widget.task).notifier)
        .updateTaskAssignee(assigneeId, ref);
    if (!mounted) return;
    ref.invalidate(myTasksProvider);

    final error = ref.read(taskDetailProvider(widget.task)).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.palette.danger),
      );
    }
  }

  /// Assign the task to a project member (or clear the assignee).
  void _pickAssignee() {
    if (!_canManage()) {
      _denied('assign this task');
      return;
    }
    final p = context.palette;
    final projectId = widget.task.projectId;
    final currentId = ref.read(taskDetailProvider(widget.task)).task.assigneeId;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      // NOTE: `sheetRef` is only for watching inside the sheet. Mutations must
      // use the screen's `ref`, which outlives the sheet — the sheet's ref is
      // disposed by Navigator.pop before the async update finishes.
      builder: (sheetCtx) => Consumer(
        builder: (context, sheetRef, _) {
          final members = sheetRef.watch(projectMembersProvider(projectId));
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHandle(),
                const SizedBox(height: 14),
                Text(
                  'Assign to',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                Text(
                  'Only project members can be assigned.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.text3,
                  ),
                ),
                const SizedBox(height: 12),
                if (members.isLoading && members.members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final m in members.members)
                            _AssigneeRow(
                              member: m,
                              selected: m.id == currentId,
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _assign(m.id);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (currentId != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _assign(null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 20,
                              color: p.danger,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Clear assignee',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Attach a file. Uses image_picker (already a dependency) and uploads bytes,
  /// so it works on mobile, desktop and web alike.
  Future<void> _attachFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    final ok = await ref
        .read(taskDetailProvider(widget.task).notifier)
        .uploadAttachmentBytes(picked.name, bytes);
    if (!mounted) return;
    setState(() => _uploading = false);

    final p = context.palette;
    if (!ok) {
      final error = ref.read(taskDetailProvider(widget.task)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Couldn't upload file"),
          backgroundColor: p.danger,
        ),
      );
    }
  }

  /// Opens the attachment in the browser / system handler so it can be
  /// downloaded. `fileUrl` is absolute for real uploads, but seeded rows store
  /// a relative path — [ApiUtils.getFullImageUrl] normalises both.
  Future<void> _download(AttachmentEntity a) async {
    final raw = ApiUtils.getFullImageUrl(a.fileUrl);
    final p = context.palette;

    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This file has no URL'),
          backgroundColor: p.danger,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid URL: $raw'), backgroundColor: p.danger),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't open file: $raw"),
          backgroundColor: p.danger,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentEntity a) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'Delete file?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.text,
          ),
        ),
        content: Text(
          '"${a.fileName}" will be permanently deleted.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: p.text2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: p.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(taskDetailProvider(widget.task).notifier)
        .deleteAttachment(a.id);
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(taskDetailProvider(widget.task)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Couldn't delete file"),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  String _fileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  // ── Relationships (Blocked by / Blocking / Related) ──────────────────────

  String _relKindLabel(TaskRelationKind k) => switch (k) {
    TaskRelationKind.blockedBy => 'Blocked by',
    TaskRelationKind.blocking => 'Blocking',
    TaskRelationKind.related => 'Related',
  };

  String _relKindHint(TaskRelationKind k) => switch (k) {
    TaskRelationKind.blockedBy =>
      "This task can't be marked Done until the linked task is Done.",
    TaskRelationKind.blocking =>
      "The linked task can't be marked Done until this task is Done.",
    TaskRelationKind.related => 'Linked for context — no ordering is enforced.',
  };

  Widget _relationships(AppPalette p, TaskEntity task, bool canManage) {
    final blockedBy = task.relations
        .where((r) => r.kind == TaskRelationKind.blockedBy)
        .toList();
    final blocking = task.relations
        .where((r) => r.kind == TaskRelationKind.blocking)
        .toList();
    final related = task.relations
        .where((r) => r.kind == TaskRelationKind.related)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Relationships',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            if (canManage)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _addRelationship(task),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: p.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (task.relations.isEmpty)
          Text(
            'No relationships yet.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: p.text3,
            ),
          )
        else ...[
          if (blockedBy.isNotEmpty)
            _relGroup(
              p,
              'BLOCKED BY',
              p.danger,
              blockedBy,
              canManage,
              showBlockerState: true,
            ),
          if (blocking.isNotEmpty)
            _relGroup(p, 'BLOCKING', p.warning, blocking, canManage),
          if (related.isNotEmpty)
            _relGroup(p, 'RELATED', p.text2, related, canManage),
        ],
      ],
    );
  }

  Widget _relGroup(
    AppPalette p,
    String title,
    Color tone,
    List<TaskRelationEntity> items,
    bool canManage, {
    bool showBlockerState = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: tone,
          ),
        ),
        const SizedBox(height: 6),
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _relRow(p, r, canManage, showBlockerState: showBlockerState),
          ),
      ],
    );
  }

  Widget _relRow(
    AppPalette p,
    TaskRelationEntity r,
    bool canManage, {
    bool showBlockerState = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          TfStatusDot(color: statusColor(p, r.taskStatus)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              r.taskTitle.isEmpty ? '(untitled)' : r.taskTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ),
          if (showBlockerState) ...[
            const SizedBox(width: 8),
            if (r.isDone)
              Icon(Icons.check_circle_rounded, size: 16, color: p.success)
            else
              Text(
                'waiting',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: p.danger,
                ),
              ),
          ],
          if (canManage) ...[
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmRemoveRelation(r),
              child: Icon(Icons.close_rounded, size: 16, color: p.text3),
            ),
          ],
        ],
      ),
    );
  }

  void _addRelationship(TaskEntity task) {
    final p = context.palette;
    var kind = TaskRelationKind.blockedBy;
    var query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final all = ref.read(taskNotifierProvider(task.projectId)).tasks;
            final existingIds = task.relations.map((r) => r.taskId).toSet();
            final q = query.trim().toLowerCase();
            final linkable = all
                .where((t) => t.id != task.id && !existingIds.contains(t.id))
                .toList();
            final candidates = linkable
                .where((t) => q.isEmpty || t.title.toLowerCase().contains(q))
                .toList();
            // Show the search box only when the list is long enough to warrant it.
            final showSearch = linkable.length > 6 || q.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 14),
                  Text(
                    'Add relationship',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in TaskRelationKind.values)
                        GestureDetector(
                          onTap: () => setSheetState(() => kind = k),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kind == k ? p.accent : p.surface2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kind == k ? p.accent : p.border,
                              ),
                            ),
                            child: Text(
                              _relKindLabel(k),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: kind == k ? p.onAccent : p.text2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _relKindHint(kind),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: p.text3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select a task',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.text2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showSearch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        autofocus: false,
                        onChanged: (v) => setSheetState(() => query = v),
                        style: TextStyle(fontSize: 13, color: p.text),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search tasks…',
                          hintStyle: TextStyle(fontSize: 13, color: p.text3),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: p.text3,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: p.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: p.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: p.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: p.accent),
                          ),
                        ),
                      ),
                    ),
                  if (candidates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        q.isEmpty
                            ? 'No other tasks to link.'
                            : 'No tasks match your search.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: p.text3,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final t in candidates)
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  _applyAddRelation(task, t.id, kind);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      TfStatusDot(
                                        color: statusColor(p, t.status),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          t.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: p.text,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: p.accent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyAddRelation(
    TaskEntity task,
    String otherTaskId,
    TaskRelationKind kind,
  ) async {
    final err = await ref
        .read(taskDetailProvider(widget.task).notifier)
        .addRelation(otherTaskId, TaskRelationEntity.kindToApi(kind));
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: context.palette.danger),
      );
    }
  }

  Future<void> _confirmRemoveRelation(TaskRelationEntity r) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'Remove relationship?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.text,
          ),
        ),
        content: Text(
          'Remove the link to "${r.taskTitle}"?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: p.text2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: p.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err = await ref
        .read(taskDetailProvider(widget.task).notifier)
        .removeRelation(r.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: p.danger));
    }
  }

  /// Edit the task description in a bottom sheet (any project member can).
  Future<void> _editDescription(TaskEntity task) async {
    final p = context.palette;
    final controller = TextEditingController(text: task.description ?? '');
    var saving = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 14),
              Text(
                'Edit description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 3,
                  cursorColor: p.accent,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: p.text,
                  ),
                  decoration: tfBareInput(
                    hint: 'Add a description…',
                    hintStyle: TextStyle(color: p.text3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TfPrimaryButton(
                label: 'Save',
                loading: saving,
                onTap: () async {
                  setSheetState(() => saving = true);
                  await ref
                      .read(taskDetailProvider(widget.task).notifier)
                      .updateTask(
                        task.copyWith(description: controller.text.trim()),
                      );
                  final err = ref.read(taskDetailProvider(widget.task)).error;
                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx);
                  if (err != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: p.danger),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(taskDetailProvider(widget.task));
    final task = state.task;

    // Assigning and setting deadlines are Owner/Admin actions.
    final me = ref.watch(authNotifierProvider).user;
    final memberState = ref.watch(projectMembersProvider(task.projectId));
    final myRole = memberState.members
        .where((m) => m.id == me?.id)
        .map((m) => m.role)
        .firstOrNull;
    final canManage = myRole == 'Owner' || myRole == 'Admin';

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Action bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: p.text2,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _starred = !_starred),
                        child: Icon(
                          _starred
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 22,
                          color: _starred ? p.warning : p.text2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _taskActions,
                        child: Icon(Icons.more_vert_rounded, size: 22, color: p.text2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TfTag(
                        text: priorityLabel(task.priority),
                        color: priorityColor(p, task.priority),
                        fontSize: 9.5,
                      ),
                      TfTag(
                        text: statusLabel(task.status),
                        color: statusColor(p, task.status),
                        fontSize: 9.5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.2,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _MetaRow(
                    icon: Icons.flag_rounded,
                    label: 'Status',
                    onTap: _pickStatus,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusPill(
                          label: statusLabel(task.status),
                          color: statusColor(p, task.status),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: p.text3,
                        ),
                      ],
                    ),
                  ),
                  _divider(context),
                  _MetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Assignee',
                    onTap: _pickAssignee,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((task.assigneeName ?? '').isEmpty)
                          Text(
                            canManage
                                ? 'Unassigned — tap to assign'
                                : 'Unassigned',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.text3,
                            ),
                          )
                        else ...[
                          TfAvatar(
                            initials: initialsOf(task.assigneeName),
                            color: avatarColorFor(
                              task.assigneeId ?? task.assigneeName!,
                            ),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.assigneeName!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                        ],
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: p.text3,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _divider(context),
                  _MetaRow(
                    icon: Icons.event_rounded,
                    label: 'Deadline',
                    onTap: _pickDeadline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.deadline == null
                              ? (canManage
                                    ? 'No deadline — tap to set'
                                    : 'No deadline')
                              : DateFormat(
                                  'MMM d, y · h:mm a',
                                ).format(task.deadline!),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: task.deadline == null ? p.text3 : p.text,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 14, color: p.text3),
                        ],
                      ],
                    ),
                  ),
                  _divider(context),
                  const SizedBox(height: 14),
                  _relationships(p, task, canManage),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _editDescription(task),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: p.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (task.description ?? '').isEmpty
                        ? 'No description provided.'
                        : task.description!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: p.text2,
                    ),
                  ),

                  // Attachments
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attachments · ${state.attachments.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                        ),
                      ),
                      GestureDetector(
                        onTap: _uploading ? null : _attachFile,
                        child: Row(
                          children: [
                            if (_uploading)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.accent,
                                ),
                              )
                            else
                              Icon(
                                Icons.attach_file_rounded,
                                size: 16,
                                color: p.accent,
                              ),
                            const SizedBox(width: 5),
                            Text(
                              _uploading ? 'Uploading…' : 'Attach file',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  if (state.attachments.isEmpty)
                    Text(
                      'No attachments yet.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.text3,
                      ),
                    )
                  else
                    for (final a in state.attachments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _AttachmentTile(
                          attachment: a,
                          sizeLabel: _fileSize(a.fileSize),
                          onDownload: () => _download(a),
                          onDelete: () => _confirmDeleteAttachment(a),
                        ),
                      ),

                  // Comments
                  const SizedBox(height: 20),
                  Text(
                    'Comments · ${state.comments.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.isLoading && state.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.comments.isEmpty)
                    Text(
                      'No comments yet. Start the conversation.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.text3,
                      ),
                    )
                  else
                    for (final c in state.comments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _Comment(comment: c),
                      ),
                ],
              ),
            ),
            // ── Comment input ───────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.border),
                      ),
                      child: TextField(
                        controller: _commentController,
                        cursorColor: p.accent,
                        onSubmitted: (_) => _sendComment(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                        ),
                        decoration: tfBareInput(
                          hint: 'Add a comment…',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.text3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _sendComment,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: p.onAccent,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: p.onAccent,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(height: 1, color: context.palette.border);

  void _taskActions() {
    final p = context.palette;
    final canManage = _canManage();
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 14),
            Text(
              'Task actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            const SizedBox(height: 12),
            if (canManage)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDeleteTask();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: p.danger),
                      const SizedBox(width: 12),
                      Text(
                        'Delete task',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                'Only Owner/Admin can delete this task.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: p.text3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTask() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'Delete task?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.task.title}"? This cannot be undone.',
          style: TextStyle(fontSize: 13, color: p.text2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: p.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(taskNotifierProvider(widget.task.projectId).notifier).deleteTask(widget.task.id);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(myTasksProvider); // update "My Tasks" too
      Navigator.pop(context);
    } else {
      final err = ref.read(taskNotifierProvider(widget.task.projectId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not delete task'), backgroundColor: p.danger),
      );
    }
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: p.surface3,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  final UserEntity member;
  final bool selected;
  final VoidCallback onTap;
  const _AssigneeRow({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            TfAvatar(
              initials: initialsOf(member.fullName),
              color: avatarColorFor(member.id),
              size: 32,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName.isNotEmpty ? member.fullName : member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  Text(
                    member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.text3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 20, color: p.accent),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.tint(color, 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Icon(icon, size: 17, color: p.text3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.text2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final AttachmentEntity attachment;
  final String sizeLabel;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  const _AttachmentTile({
    required this.attachment,
    required this.sizeLabel,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TfCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      radius: 13,
      child: Row(
        children: [
          TfIconBadge(
            icon: Icons.description_outlined,
            color: p.accent,
            size: 34,
            radius: 9,
            iconSize: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                Text(
                  '$sizeLabel · ${attachment.uploaderFullName}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.text3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDownload,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.download_rounded, size: 20, color: p.accent),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: p.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  final CommentEntity comment;
  const _Comment({required this.comment});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TfAvatar(
          initials: initialsOf(comment.userFullName),
          color: avatarColorFor(comment.userId),
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.userFullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    timeago.format(comment.createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: p.text3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: p.text2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
