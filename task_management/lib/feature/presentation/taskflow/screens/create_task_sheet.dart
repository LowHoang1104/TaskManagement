import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/task_provider.dart';
import '../widgets/tf_widgets.dart';

/// Shows the "New task" bottom sheet — `TaskFlow.dc.html` (05 — Add & flows),
/// wired to `taskNotifierProvider(projectId).createTask(...)`.
Future<void> showCreateTaskSheet(BuildContext context,
    {required String projectId}) {
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
  final _descController = TextEditingController();
  int _status = 0; // To Do / In Progress / Review
  int _priority = 1; // Low / Normal / High / Critical
  bool _saving = false;

  static const _statuses = [TaskStatus.todo, TaskStatus.doing, TaskStatus.review];
  static const _priorities = [
    TaskPriority.low,
    TaskPriority.medium,
    TaskPriority.high,
    TaskPriority.critical,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
        .createTask(title, _descController.text.trim(), _statuses[_status],
            _priorities[_priority]);
    if (!mounted) return;
    setState(() => _saving = false);
    if (created != null) {
      Navigator.pop(context);
    } else {
      final error = ref.read(taskNotifierProvider(widget.projectId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to create task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: p.surface3, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New task',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: p.text)),
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
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: p.text),
                decoration: tfBareInput(
                  hint: 'Task title',
                  hintStyle: TextStyle(color: p.text3),
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              minLines: 1,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text2),
              decoration: tfBareInput(
                hint: 'Add a description…',
                hintStyle: TextStyle(color: p.text3, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 20),
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
