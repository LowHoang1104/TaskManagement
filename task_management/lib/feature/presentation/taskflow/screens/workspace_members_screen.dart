import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_members_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Workspace members — the entry point of the membership flow.
///
/// People are invited to a **workspace by email** here; only workspace members
/// can then be added to a project (see `invite_member_dialog.dart`, which picks
/// from this list). The backend enforces the same rule.
class WorkspaceMembersScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final String workspaceName;

  const WorkspaceMembersScreen({
    super.key,
    required this.workspaceId,
    this.workspaceName = 'Workspace',
  });

  @override
  ConsumerState<WorkspaceMembersScreen> createState() =>
      _WorkspaceMembersScreenState();
}

class _WorkspaceMembersScreenState
    extends ConsumerState<WorkspaceMembersScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    final ok = await ref
        .read(workspaceMembersProvider(widget.workspaceId).notifier)
        .inviteMember(email);
    if (!mounted) return;
    setState(() => _sending = false);
    final p = context.palette;
    if (ok) {
      _emailController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invitation sent — waiting for them to accept'),
          backgroundColor: p.success,
        ),
      );
    } else {
      final error = ref
          .read(workspaceMembersProvider(widget.workspaceId))
          .error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Could not invite member'),
          backgroundColor: p.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(workspaceMembersProvider(widget.workspaceId));
    final me = ref.watch(authNotifierProvider).user;
    final myRole = state.members
        .where((m) => m.id == me?.id)
        .map((m) => m.role)
        .firstOrNull;
    final canInvite = myRole == 'Owner' || myRole == 'Admin';
    final isOwner = myRole == 'Owner';

    return Scaffold(
      backgroundColor: p.surface2,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: p.text2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: p.text,
                          ),
                        ),
                        Text(
                          '${widget.workspaceName} · ${state.members.length} people',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: p.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: state.isLoading && state.members.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(
                            workspaceMembersProvider(
                              widget.workspaceId,
                            ).notifier,
                          )
                          .fetchMembers(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          if (canInvite) ...[
                            TfCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      TfIconBadge(
                                        icon: Icons.mail_outline_rounded,
                                        color: p.accent,
                                        size: 34,
                                        iconSize: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Invite to workspace',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: p.text,
                                              ),
                                            ),
                                            Text(
                                              'They get an invite and must accept to join.',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: p.text3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  TfLabeledField(
                                    label: 'Email',
                                    icon: Icons.alternate_email_rounded,
                                    controller: _emailController,
                                    hint: 'name@company.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  TfPrimaryButton(
                                    label: 'Send invite',
                                    loading: _sending,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    onTap: _invite,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          TfSectionLabel(
                            'Members · ${state.members.length}',
                            padding: const EdgeInsets.fromLTRB(2, 0, 0, 10),
                          ),
                          if (state.error != null && state.members.isEmpty)
                            Text(
                              state.error!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: p.danger,
                              ),
                            )
                          else
                            for (final m in state.members)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MemberRow(
                                  member: m,
                                  isMe: m.id == me?.id,
                                  canManage: isOwner && m.role != 'Owner',
                                  onManage: () => _memberActions(m),
                                ),
                              ),
                        ],
                      ),
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
      workspaceMembersProvider(widget.workspaceId).notifier,
    );
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
            if (member.role != 'Admin')
              _Action(
                icon: Icons.shield_outlined,
                label: 'Make Admin',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  notifier.updateRole(member.id, 'Admin');
                },
              ),
            if (member.role != 'Member')
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
              label: 'Remove from workspace',
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

class _MemberRow extends StatelessWidget {
  final UserEntity member;
  final bool isMe;
  final bool canManage;
  final VoidCallback onManage;
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canManage,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TfCard(
      radius: 15,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          TfAvatar(
            initials: initialsOf(member.fullName),
            color: avatarColorFor(member.id),
            size: 36,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName
                            : member.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(you)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.text3,
                        ),
                      ),
                    ],
                  ],
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
          const SizedBox(width: 8),
          if (member.status == 'Pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p.tint(p.warning, 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'PENDING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: p.warning,
                ),
              ),
            )
          else
            RoleBadge(role: member.role ?? 'Member'),
          if (canManage)
            GestureDetector(
              onTap: onManage,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.more_vert_rounded, size: 18, color: p.text3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Owner / Admin / Member pill.
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (role) {
      'Owner' => p.accent,
      'Admin' => p.warning,
      _ => p.text2,
    };
    final bg = role == 'Member' ? p.surface3 : p.tint(color, 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}
