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
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_members_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_detail_provider.dart';
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
    await ref
        .read(taskDetailProvider(widget.task).notifier)
        .addComment(text);
    _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }

  /// Move the task between statuses (To Do → In Progress → Review → Done).
  void _pickStatus() {
    final p = context.palette;
    final current = ref.read(taskDetailProvider(widget.task)).task.status;
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
            Text('Move task to',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 12),
            for (final s in TaskStatus.values)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (s == current) return;
                  await ref
                      .read(taskDetailProvider(widget.task).notifier)
                      .updateStatus(s, ref);
                  if (!mounted) return;
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
                        child: Text(statusLabel(s),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.text)),
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
    final members = ref.read(projectMembersProvider(widget.task.projectId)).members;
    final myRole =
        members.where((m) => m.id == me?.id).map((m) => m.role).firstOrNull;
    return myRole == 'Owner' || myRole == 'Admin';
  }

  void _denied(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chỉ Owner/Admin mới được $what.'),
        backgroundColor: context.palette.text2,
      ),
    );
  }

  /// Pick a date + time for the deadline (Owner/Admin only).
  Future<void> _pickDeadline() async {
    if (!_canManage()) {
      _denied('chỉnh deadline');
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
      _denied('giao task');
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
                Text('Assign to',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
                Text('Only project members can be assigned.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.text3)),
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
                        child: Row(children: [
                          Icon(Icons.person_off_outlined,
                              size: 20, color: p.danger),
                          const SizedBox(width: 12),
                          Text('Clear assignee',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: p.danger)),
                        ]),
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
            content: Text(error ?? 'Không tải được file'),
            backgroundColor: p.danger),
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
        SnackBar(content: const Text('File này không có đường dẫn'), backgroundColor: p.danger),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đường dẫn không hợp lệ: $raw'), backgroundColor: p.danger),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được file: $raw'), backgroundColor: p.danger),
      );
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentEntity a) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Xoá file?',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
        content: Text('"${a.fileName}" sẽ bị xoá vĩnh viễn.',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: p.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xoá', style: TextStyle(color: p.danger)),
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
            content: Text(error ?? 'Không xoá được file'),
            backgroundColor: context.palette.danger),
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
                    child: Icon(Icons.arrow_back_rounded, size: 24, color: p.text2),
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
                            color: _starred ? p.warning : p.text2),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.more_vert_rounded, size: 22, color: p.text2),
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
                          fontSize: 9.5),
                      TfTag(
                          text: statusLabel(task.status),
                          color: statusColor(p, task.status),
                          fontSize: 9.5),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(task.title,
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.2,
                          color: p.text)),
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
                            color: statusColor(p, task.status)),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more_rounded, size: 16, color: p.text3),
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
                                  color: p.text3))
                        else ...[
                          TfAvatar(
                              initials: initialsOf(task.assigneeName),
                              color: avatarColorFor(
                                  task.assigneeId ?? task.assigneeName!),
                              size: 24),
                          const SizedBox(width: 8),
                          Text(task.assigneeName!,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.text)),
                        ],
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded,
                              size: 16, color: p.text3),
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
                                : DateFormat('MMM d, y · h:mm a')
                                    .format(task.deadline!),
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: task.deadline == null ? p.text3 : p.text)),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 14, color: p.text3),
                        ],
                      ],
                    ),
                  ),
                  if (task.dependencies.isNotEmpty) ...[
                    _divider(context),
                    _MetaRow(
                      icon: Icons.link_rounded,
                      label: 'Blocked by',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.tint(p.danger, 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: p.danger),
                            const SizedBox(width: 5),
                            Text('${task.dependencies.length} blocker(s)',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.danger)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    (task.description ?? '').isEmpty
                        ? 'No description provided.'
                        : task.description!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        color: p.text2),
                  ),

                  // Attachments
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attachments · ${state.attachments.length}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: p.text)),
                      GestureDetector(
                        onTap: _uploading ? null : _attachFile,
                        child: Row(
                          children: [
                            if (_uploading)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: p.accent),
                              )
                            else
                              Icon(Icons.attach_file_rounded,
                                  size: 16, color: p.accent),
                            const SizedBox(width: 5),
                            Text(_uploading ? 'Uploading…' : 'Attach file',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: p.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  if (state.attachments.isEmpty)
                    Text('No attachments yet.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.text3))
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
                  Text('Comments · ${state.comments.length}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                  const SizedBox(height: 12),
                  if (state.isLoading && state.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.comments.isEmpty)
                    Text('No comments yet. Start the conversation.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.text3))
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
                          horizontal: 15, vertical: 4),
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
                            color: p.text),
                        decoration: tfBareInput(
                          hint: 'Add a comment…',
                          hintStyle: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.text3),
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
                          color: p.accent, shape: BoxShape.circle),
                      child: _sending
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: p.onAccent),
                            )
                          : Icon(Icons.send_rounded,
                              size: 20, color: p.onAccent),
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
            color: p.surface3, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  final UserEntity member;
  final bool selected;
  final VoidCallback onTap;
  const _AssigneeRow(
      {required this.member, required this.selected, required this.onTap});

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
                size: 32),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName.isNotEmpty ? member.fullName : member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.text)),
                  Text(member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.text3)),
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
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.text3)),
                ],
              ),
            ),
            Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
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
              iconSize: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.text)),
                Text('$sizeLabel · ${attachment.uploaderFullName}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.text3)),
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
              child:
                  Icon(Icons.delete_outline_rounded, size: 20, color: p.danger),
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
            size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(comment.userFullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.text)),
                  ),
                  const SizedBox(width: 7),
                  Text(timeago.format(comment.createdAt),
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: p.text3)),
                ],
              ),
              const SizedBox(height: 2),
              Text(comment.content,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: p.text2)),
            ],
          ),
        ),
      ],
    );
  }
}
