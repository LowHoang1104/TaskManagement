import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../providers/project_members_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Shows the "Invite to project" dialog — `TaskFlow.dc.html` (05 — Add & flows),
/// wired to `projectMembersProvider(projectId)`.
Future<void> showInviteMemberDialog(BuildContext context,
    {required String projectId}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _InviteMemberDialog(projectId: projectId),
  );
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final String projectId;
  const _InviteMemberDialog({required this.projectId});

  @override
  ConsumerState<_InviteMemberDialog> createState() =>
      _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  int _role = 1; // Admin / Member (visual — backend assigns default role)
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    final ok = await ref
        .read(projectMembersProvider(widget.projectId).notifier)
        .inviteMember(email);
    if (!mounted) return;
    setState(() => _sending = false);
    final p = context.palette;
    if (ok) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Invitation sent'), backgroundColor: p.success),
      );
    } else {
      final error = ref.read(projectMembersProvider(widget.projectId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Failed to send invite'),
            backgroundColor: p.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final membersState = ref.watch(projectMembersProvider(widget.projectId));
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: p.accentWeak, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Icon(Icons.group_add_rounded, size: 24, color: p.accent),
            ),
            const SizedBox(height: 14),
            Text('Invite to project',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: p.text)),
            const SizedBox(height: 4),
            Text("They'll get an invite in their inbox.",
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text3)),
            const SizedBox(height: 18),

            TfSectionLabel('Email'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border2, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline_rounded, size: 18, color: p.text3),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      cursorColor: p.accent,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.text),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'name@company.com',
                        hintStyle: TextStyle(color: p.text3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TfSectionLabel('Role'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleChip(
                      label: 'Admin',
                      selected: _role == 0,
                      onTap: () => setState(() => _role = 0)),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RoleChip(
                      label: 'Member',
                      selected: _role == 1,
                      onTap: () => setState(() => _role = 1)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: p.border, height: 1),
            const SizedBox(height: 12),

            TfSectionLabel('Members · ${membersState.members.length}'),
            const SizedBox(height: 9),
            if (membersState.isLoading && membersState.members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4))),
              )
            else
              ...membersState.members.take(4).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        TfAvatar(
                            initials: initialsOf(m.fullName),
                            color: avatarColorFor(m.id),
                            size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.fullName.isNotEmpty ? m.fullName : m.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: p.text)),
                              Text(m.role ?? 'Member',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.text3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            TfPrimaryButton(
              label: 'Send invite',
              loading: _sending,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.accent : p.surface2,
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: p.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? p.onAccent : p.text2)),
      ),
    );
  }
}
