import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/project_members_provider.dart';
import '../../providers/task_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Shows the "New task" bottom sheet — a lightweight create flow: name, status,
/// priority and assignee only. Everything else (description, deadline,
/// relationships) is edited afterwards on the task detail screen.
Future<void> showCreateTaskSheet(
  BuildContext context, {
  required String projectId,
}) {
  final p = context.palette;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _CreateTaskSheet(projectId: projectId),
  );
}

class _CreateTaskSheet extends ConsumerStatefulWidget {
  final String projectId;
  const _CreateTaskSheet({required this.projectId});

  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _titleController = TextEditingController();
  int _status = 0; // To Do / In Progress / Review
  int _priority = 1; // Low / Normal / High / Critical
  String? _assigneeId; // person in charge (optional)
  bool _saving = false;

  static const _statuses = [
    TaskStatus.todo,
    TaskStatus.doing,
    TaskStatus.review,
  ];
  static const _priorities = [
    TaskPriority.low,
    TaskPriority.medium,
    TaskPriority.high,
    TaskPriority.critical,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }
    setState(() => _saving = true);
    final created = await ref
        .read(taskNotifierProvider(widget.projectId).notifier)
        .createTask(
          title,
          '',
          _statuses[_status],
          _priorities[_priority],
          assigneeId: _assigneeId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (created != null) {
      Navigator.pop(context);
    } else {
      final error = ref.read(taskNotifierProvider(widget.projectId)).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Failed to create task')));
    }
  }

  /// A single selectable chip (used for the assignee picker).
  Widget _selectChip(
    AppPalette p, {
    required Widget child,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? p.tint(p.accent, 0.16) : p.surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? p.tint(p.accent, 0.4) : p.border,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final membersState = ref.watch(projectMembersProvider(widget.projectId));
    final members = membersState.members;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: p.text,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded, size: 24, color: p.text3),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title (accent underline)
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.accent, width: 2)),
              ),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                cursorColor: p.accent,
                onSubmitted: (_) => _create(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
                decoration: tfBareInput(
                  hint: 'Task title',
                  hintStyle: TextStyle(color: p.text3),
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            TfSectionLabel('Status'),
            const SizedBox(height: 9),
            _ChipRow(
              labels: const ['To Do', 'In Progress', 'Review'],
              selected: _status,
              onSelect: (i) => setState(() => _status = i),
            ),
            const SizedBox(height: 16),

            TfSectionLabel('Priority'),
            const SizedBox(height: 9),
            _ChipRow(
              labels: const ['Low', 'Normal', 'High', 'Critical'],
              selected: _priority,
              tone: p.warning,
              onSelect: (i) => setState(() => _priority = i),
            ),
            const SizedBox(height: 16),

            TfSectionLabel('Assignee'),
            const SizedBox(height: 9),
            if (membersState.isLoading && members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _selectChip(
                    p,
                    selected: _assigneeId == null,
                    onTap: () => setState(() => _assigneeId = null),
                    child: Text(
                      'Unassigned',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _assigneeId == null ? p.accent : p.text2,
                      ),
                    ),
                  ),
                  for (final m in members)
                    _selectChip(
                      p,
                      selected: _assigneeId == m.id,
                      onTap: () => setState(() => _assigneeId = m.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TfAvatar(
                            initials: initialsOf(m.fullName),
                            color: avatarColorFor(m.id),
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              m.fullName.isNotEmpty ? m.fullName : m.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _assigneeId == m.id ? p.accent : p.text2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 22),
            TfPrimaryButton(
              label: 'Create task',
              loading: _saving,
              onTap: _create,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final Color? tone;
  final ValueChanged<int> onSelect;
  const _ChipRow({
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = tone ?? p.accent;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: i == selected
                    ? (tone == null ? accent : p.tint(accent, 0.16))
                    : p.surface2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: i == selected
                      ? (tone == null ? accent : p.tint(accent, 0.4))
                      : p.border,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: i == selected
                      ? (tone == null ? p.onAccent : accent)
                      : p.text2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
