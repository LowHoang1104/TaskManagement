import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/notification_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/workspace_members_provider.dart';
import '../widgets/tf_widgets.dart';

/// Notifications inbox — redesigned UI from `TaskFlow.dc.html` (04 — System),
/// wired to `notificationProvider` (mark read, accept/decline invites).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(notificationProvider);
    final unread = state.notifications.where((n) => !n.isRead).toList();
    final read = state.notifications.where((n) => n.isRead).toList();

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
                  Text('Inbox',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: p.text)),
                  GestureDetector(
                    onTap: unread.isEmpty
                        ? null
                        : () {
                            for (final n in unread) {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markAsRead(n.id);
                            }
                          },
                    child: Text('Mark all read',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: unread.isEmpty ? p.text3 : p.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  TfPill(
                      label: 'All',
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false)),
                  const SizedBox(width: 8),
                  TfPill(
                      label: 'Unread · ${unread.length}',
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true)),
                ],
              ),
            ],
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: p.surface2,
            child: _body(context, state, unread, read),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, NotificationState state,
      List<NotificationEntity> unread, List<NotificationEntity> read) {
    final p = context.palette;
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.notifications.isEmpty) {
      return _empty(context, 'You’re all caught up',
          'New activity on your projects will show up here.');
    }
    if (_unreadOnly && unread.isEmpty) {
      return _empty(context, 'No unread notifications', 'Nice and tidy.');
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationProvider.notifier).fetchNotifications(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (unread.isNotEmpty) ...[
            TfSectionLabel('New',
                padding: const EdgeInsets.fromLTRB(4, 8, 0, 8)),
            for (final n in unread)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _NotifCard(notification: n),
              ),
          ],
          if (!_unreadOnly && read.isNotEmpty) ...[
            const SizedBox(height: 8),
            TfSectionLabel('Earlier',
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 8)),
            for (final n in read)
              _EarlierRow(notification: n),
          ],
          if (!_unreadOnly && read.isEmpty && unread.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                  child: Text('Nothing here',
                      style: TextStyle(color: p.text3))),
            ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String title, String subtitle) {
    final p = context.palette;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.notifications_none_rounded, size: 56, color: p.text3),
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

bool _isInvite(NotificationEntity n) => n.type.toLowerCase() == 'invite';

IconData _iconFor(NotificationEntity n) {
  if (_isInvite(n)) return Icons.group_add_rounded;
  final t = n.type.toLowerCase();
  if (t.contains('comment')) return Icons.chat_bubble_rounded;
  if (t.contains('assign')) return Icons.assignment_ind_rounded;
  if (t.contains('complete') || t.contains('done')) {
    return Icons.check_circle_rounded;
  }
  if (t.contains('deadline') || t.contains('due')) {
    return Icons.event_available_rounded;
  }
  return Icons.notifications_rounded;
}

class _NotifCard extends ConsumerWidget {
  final NotificationEntity notification;
  const _NotifCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isInvite = _isInvite(notification);
    final iconColor = isInvite ? p.accent : p.warning;
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
      },
      child: TfCard(
        radius: 15,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TfIconBadge(
                icon: _iconFor(notification),
                color: iconColor,
                size: 38,
                radius: 11,
                iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          color: p.text)),
                  const SizedBox(height: 3),
                  Text(timeago.format(notification.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.text3)),
                  if (isInvite &&
                      !notification.isRead &&
                      notification.relatedId != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InviteAction(
                          label: 'Accept',
                          filled: true,
                          onTap: () => _respond(context, ref, accept: true),
                        ),
                        const SizedBox(width: 8),
                        _InviteAction(
                          label: 'Decline',
                          filled: false,
                          onTap: () => _respond(context, ref, accept: false),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref,
      {required bool accept}) async {
    final p = context.palette;
    final notifier = ref.read(notificationProvider.notifier);
    // "Invite" notifications are workspace invites — joining a workspace needs
    // acceptance, whereas project members are added directly.
    final ok = accept
        ? await notifier.acceptWorkspaceInvite(
            notification.relatedId!, notification.id)
        : await notifier.declineWorkspaceInvite(
            notification.relatedId!, notification.id);
    if (!context.mounted) return;
    if (ok) {
      // The workspace list changes on accept/decline; the member list must also
      // refetch so the just-accepted invite no longer shows as "Pending".
      ref.invalidate(workspaceNotifierProvider);
      ref.invalidate(workspaceMembersProvider(notification.relatedId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(accept ? 'Joined the workspace' : 'Invitation declined'),
            backgroundColor: accept ? p.success : p.text2),
      );
    } else {
      final error = ref.read(notificationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Something went wrong'),
            backgroundColor: p.danger),
      );
    }
  }
}

class _InviteAction extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _InviteAction(
      {required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? p.accent : p.surface2,
          borderRadius: BorderRadius.circular(9),
          border: filled ? null : Border.all(color: p.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filled ? p.onAccent : p.text2)),
      ),
    );
  }
}

class _EarlierRow extends ConsumerWidget {
  final NotificationEntity notification;
  const _EarlierRow({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TfIconBadge(
              icon: _iconFor(notification),
              color: p.text2,
              background: p.surface3,
              size: 38,
              radius: 11,
              iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: p.text2)),
                const SizedBox(height: 3),
                Text(timeago.format(notification.createdAt),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
