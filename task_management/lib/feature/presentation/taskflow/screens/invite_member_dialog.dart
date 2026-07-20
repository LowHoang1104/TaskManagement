import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_members_provider.dart';
import '../../providers/workspace_members_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';
import 'workspace_members_screen.dart';

/// Add people to a **project** by picking them from the workspace.
///
/// Membership flow: you invite someone to the *workspace* by email
/// ([WorkspaceMembersScreen]); only workspace members can then be added to a
/// project — so here you search the workspace roster by name/email instead of
/// typing a raw address. The backend enforces the same rule
/// ("This user is not a member of the workspace.").
Future<void> showInviteMemberDialog(
  BuildContext context, {
  required String projectId,
  required String workspaceId,
  String workspaceName = 'Workspace',
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _InviteMemberDialog(
      projectId: projectId,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    ),
  );
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String workspaceId;
  final String workspaceName;
  const _InviteMemberDialog({
    required this.projectId,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  ConsumerState<_InviteMemberDialog> createState() =>
      _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _addingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add(UserEntity user) async {
    setState(() => _addingId = user.id);
    final ok = await ref
        .read(projectMembersProvider(widget.projectId).notifier)
        .inviteMember(user.email);
    if (!mounted) return;
    setState(() => _addingId = null);
    final p = context.palette;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Added ${user.fullName} to the project'),
            backgroundColor: p.success),
      );
    } else {
      final error = ref.read(projectMembersProvider(widget.projectId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Could not add member'),
            backgroundColor: p.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final projectState = ref.watch(projectMembersProvider(widget.projectId));
    final workspaceState = ref.watch(workspaceMembersProvider(widget.workspaceId));
    final me = ref.watch(authNotifierProvider).user;
    
    final myRole = projectState.members
        .where((m) => m.id == me?.id)
        .map((m) => m.role)
        .firstOrNull;
    final isOwner = myRole == 'Owner';
    final isAdmin = myRole == 'Admin';

    final memberIds = projectState.members.map((m) => m.id).toSet();
    final q = _query.trim().toLowerCase();
    // Only people who have actually joined the workspace (a pending invite
    // doesn't count) and aren't in the project yet.
    final candidates = workspaceState.members
        .where((m) => m.status != 'Pending')
        .where((m) => !memberIds.contains(m.id))
        .where((m) =>
            q.isEmpty ||
            m.fullName.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q))
        .toList();

    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
            Text('Add to project',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: p.text)),
            const SizedBox(height: 4),
            Text('Pick from ${widget.workspaceName}. Only workspace members can join a project.',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: p.text3)),
            const SizedBox(height: 16),

            TfLabeledField(
              label: 'Search',
              icon: Icons.search_rounded,
              controller: _searchController,
              hint: 'Name or email',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 14),

            // ── Candidates ────────────────────────────────────────────
            if (workspaceState.isLoading && workspaceState.members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (candidates.isEmpty)
              _EmptyCandidates(
                everyoneAdded: q.isEmpty,
                onInviteToWorkspace: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkspaceMembersScreen(
                        workspaceId: widget.workspaceId,
                        workspaceName: widget.workspaceName,
                      ),
                    ),
                  );
                },
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 210),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = candidates[i];
                    return _CandidateRow(
                      user: u,
                      adding: _addingId == u.id,
                      onAdd: () => _add(u),
                    );
                  },
                ),
              ),

            // ── Already in the project ────────────────────────────────
            const SizedBox(height: 16),
            Divider(color: p.border, height: 1),
            const SizedBox(height: 12),
            TfSectionLabel('In this project · ${projectState.members.length}'),
            const SizedBox(height: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final m in projectState.members)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            TfAvatar(
                                initials: initialsOf(m.fullName),
                                color: avatarColorFor(m.id),
                                size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  m.fullName.isNotEmpty ? m.fullName : m.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: p.text)),
                            ),
                            RoleBadge(role: m.role ?? 'Member'),
                            if (m.id != me?.id && (isOwner || (isAdmin && m.role != 'Owner')))
                              GestureDetector(
                                onTap: () => _memberActions(m),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.more_vert_rounded, size: 18, color: p.text3),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _memberActions(UserEntity member) {
    final p = context.palette;
    final notifier = ref.read(
      projectMembersProvider(widget.projectId).notifier,
    );
    final myRole = ref.read(projectMembersProvider(widget.projectId)).members
        .where((m) => m.id == ref.read(authNotifierProvider).user?.id)
        .map((m) => m.role)
        .firstOrNull;
    final isOwner = myRole == 'Owner';

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
            Text(
              member.fullName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            Text(
              member.email,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.text3,
              ),
            ),
            const SizedBox(height: 12),
            if (isOwner && member.role != 'Admin')
              _Action(
                icon: Icons.shield_outlined,
                label: 'Make Admin',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  notifier.updateRole(member.id, 'Admin');
                },
              ),
            if (isOwner && member.role != 'Member')
              _Action(
                icon: Icons.person_outline_rounded,
                label: 'Make Member',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  notifier.updateRole(member.id, 'Member');
                },
              ),
            _Action(
              icon: Icons.person_remove_alt_1_rounded,
              label: 'Remove from project',
              danger: true,
              onTap: () {
                Navigator.pop(sheetCtx);
                notifier.removeMember(member.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.danger : p.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final UserEntity user;
  final bool adding;
  final VoidCallback onAdd;
  const _CandidateRow(
      {required this.user, required this.adding, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        TfAvatar(
            initials: initialsOf(user.fullName),
            color: avatarColorFor(user.id),
            size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName.isNotEmpty ? user.fullName : user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.text)),
              Text(user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.text3)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: adding ? null : onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: adding
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.onAccent),
                  )
                : Text('Add',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.onAccent)),
          ),
        ),
      ],
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  final bool everyoneAdded;
  final VoidCallback onInviteToWorkspace;
  const _EmptyCandidates(
      {required this.everyoneAdded, required this.onInviteToWorkspace});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Icon(everyoneAdded ? Icons.groups_rounded : Icons.search_off_rounded,
              size: 28, color: p.text3),
          const SizedBox(height: 8),
          Text(
              everyoneAdded
                  ? 'Everyone in this workspace is already in the project.'
                  : 'No workspace member matches your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: p.text3)),
          if (everyoneAdded) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onInviteToWorkspace,
              child: Text('Invite someone to the workspace →',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.accent)),
            ),
          ],
        ],
      ),
    );
  }
}
