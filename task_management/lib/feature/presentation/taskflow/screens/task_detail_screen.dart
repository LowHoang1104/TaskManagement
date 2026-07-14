import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/comment_entity.dart';
import '../../../domain/entities/attachment_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/task_detail_provider.dart';
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
                    child: _StatusPill(
                        label: statusLabel(task.status),
                        color: statusColor(p, task.status)),
                  ),
                  _divider(context),
                  _MetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Assignee',
                    child: (task.assigneeName ?? '').isEmpty
                        ? Text('Unassigned',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: p.text3))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                          ),
                  ),
                  _divider(context),
                  _MetaRow(
                    icon: Icons.event_rounded,
                    label: 'Deadline',
                    child: Text(
                        task.deadline == null
                            ? 'No deadline'
                            : DateFormat('MMM d, y · h:mm a')
                                .format(task.deadline!),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.text)),
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
                  if (state.attachments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Attachments · ${state.attachments.length}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: p.text)),
                    const SizedBox(height: 11),
                    for (final a in state.attachments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _AttachmentTile(
                            attachment: a, sizeLabel: _fileSize(a.fileSize)),
                      ),
                  ],

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
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Add a comment…',
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
  const _MetaRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
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
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final AttachmentEntity attachment;
  final String sizeLabel;
  const _AttachmentTile({required this.attachment, required this.sizeLabel});

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
          Icon(Icons.download_rounded, size: 20, color: p.text3),
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
