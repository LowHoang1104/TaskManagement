import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Create project — redesigned UI from `TaskFlow.dc.html` (05 — Add & flows),
/// wired to `projectNotifierProvider(workspaceId).createProject(...)`.
class CreateProjectScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final String workspaceName;
  const CreateProjectScreen({
    super.key,
    required this.workspaceId,
    this.workspaceName = 'Workspace',
  });

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  static const _swatches = [
    Color(0xFF2F6BFF),
    Color(0xFF7C3AED),
    Color(0xFF22A35B),
    Color(0xFFE08A13),
    Color(0xFFE5484D),
  ];
  int _color = 0;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(projectNotifierProvider(widget.workspaceId).notifier)
        .createProject(widget.workspaceId, name, _descController.text.trim());
    if (!mounted) return;
    final error = ref.read(projectNotifierProvider(widget.workspaceId)).error;
    setState(() => _saving = false);
    if (error == null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.palette.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = ref.watch(authNotifierProvider).user;
    final projectColor = _swatches[_color];
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.close_rounded, size: 24, color: p.text2),
                  ),
                  Text('New project',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                  GestureDetector(
                    onTap: _saving ? null : _create,
                    child: Text('Save',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.accent)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: projectColor,
                            borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: Icon(Icons.rocket_launch_rounded,
                            size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _swatches.length; i++)
                              GestureDetector(
                                onTap: () => setState(() => _color = i),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _swatches[i],
                                    shape: BoxShape.circle,
                                    border: i == _color
                                        ? Border.all(color: p.surface, width: 2)
                                        : null,
                                    boxShadow: i == _color
                                        ? [
                                            BoxShadow(
                                                color: _swatches[i],
                                                blurRadius: 0,
                                                spreadRadius: 2)
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TfSectionLabel('Project name'),
                  const SizedBox(height: 8),
                  _Box(
                    focused: true,
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      cursorColor: p.accent,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.text),
                      decoration: _dec(context, 'e.g. Website Revamp'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TfSectionLabel('Description'),
                  const SizedBox(height: 8),
                  _Box(
                    minHeight: 56,
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      cursorColor: p.accent,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: p.text2),
                      decoration: _dec(context, 'What is this project about?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TfSectionLabel('Workspace'),
                  const SizedBox(height: 8),
                  _Box(
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(7)),
                          alignment: Alignment.center,
                          child: Text(
                              widget.workspaceName.isNotEmpty
                                  ? widget.workspaceName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: p.onAccent)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(widget.workspaceName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.text)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TfSectionLabel('Members'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TfAvatar(
                          initials: initialsOf(user?.fullName),
                          color: p.accent,
                          size: 36),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You can invite members after creating the project.')),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: p.border2, width: 1.5),
                          ),
                          child: Icon(Icons.add_rounded, size: 20, color: p.text3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TfPrimaryButton(
                label: 'Create project',
                loading: _saving,
                onTap: _create,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: TextStyle(color: context.palette.text3),
      );
}

class _Box extends StatelessWidget {
  final Widget child;
  final bool focused;
  final double? minHeight;
  const _Box({required this.child, this.focused = false, this.minHeight});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: focused ? p.accent : p.border2, width: 1.5),
        boxShadow: focused
            ? [BoxShadow(color: p.accentWeak, blurRadius: 0, spreadRadius: 3)]
            : null,
      ),
      child: child,
    );
  }
}
