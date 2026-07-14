import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/workspace_provider.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';

/// Home / Dashboard — redesigned UI from `TaskFlow.dc.html` (02 — Home), wired
/// to live data (dashboard stats, current user, unread inbox count).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(authNotifierProvider).user;
    final name = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : 'there';
    final unread = ref.watch(notificationProvider).unreadCount;
    final dashboard = ref.watch(dashboardProvider);

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          color: p.surface,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.text3)),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: p.text)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 24, color: p.text2),
                  if (unread > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showTweaks(context, ref),
                child: TfAvatar(
                  initials: initialsOf(user?.fullName),
                  color: p.accentWeak,
                  textColor: p.accent,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: p.surface2,
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardProvider.notifier).fetchDashboardStats(),
              child: dashboard.when(
                loading: () => ListView(
                  children: const [
                    SizedBox(height: 240),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [_ErrorBox(message: '$e')],
                ),
                data: (d) {
                  final total =
                      d.totalTasksDone + d.tasksToDo + d.tasksInProgress + d.tasksReview;
                  final progress = total == 0 ? 0.0 : d.totalTasksDone / total;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              value: '${d.totalTasksDone}',
                              label: 'Done this week',
                              accent: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bolt_rounded,
                              value: '${d.totalTasksOngoing}',
                              label: 'Ongoing tasks',
                              accent: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _WeeklyProgress(
                        percent: progress,
                        done: d.totalTasksDone,
                        total: total,
                      ),
                      const SizedBox(height: 16),
                      TfSectionLabel('By status',
                          padding: const EdgeInsets.fromLTRB(2, 0, 0, 10)),
                      _StatusRow(
                          color: p.statusTodo, label: 'To Do', count: d.tasksToDo),
                      const SizedBox(height: 9),
                      _StatusRow(
                          color: p.accent,
                          label: 'In Progress',
                          count: d.tasksInProgress),
                      const SizedBox(height: 9),
                      _StatusRow(
                          color: p.statusReview,
                          label: 'Review',
                          count: d.tasksReview),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTweaks(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeProvider);
          final accent = ref.watch(accentProvider);
          final platformDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final isDark = mode == ThemeMode.dark ||
              (mode == ThemeMode.system && platformDark);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                const SizedBox(height: 18),
                Text('Tweaks',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 20,
                        color: p.text2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Dark theme',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.text)),
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: p.accent,
                      onChanged: (v) => ref
                          .read(themeProvider.notifier)
                          .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Accent',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.text2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final c in AccentNotifier.options)
                      GestureDetector(
                        onTap: () =>
                            ref.read(accentProvider.notifier).setAccent(c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            boxShadow: accent.toARGB32() == c.toARGB32()
                                ? [
                                    BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 0,
                                        spreadRadius: 3)
                                  ]
                                : null,
                          ),
                          child: accent.toARGB32() == c.toARGB32()
                              ? const Icon(Icons.check_rounded,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: p.border, height: 1),
                const SizedBox(height: 6),
                _SheetAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile & settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),
                _SheetAction(
                  icon: Icons.logout_rounded,
                  label: 'Log out',
                  danger: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).logout();
                    ref.invalidate(workspaceNotifierProvider);
                    ref.invalidate(projectNotifierProvider);
                    ref.invalidate(taskNotifierProvider);
                    ref.invalidate(notificationProvider);
                    ref.invalidate(dashboardProvider);
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.login, (r) => false);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _SheetAction({
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
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TfCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: p.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text2)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool accent;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = accent ? p.onAccent : p.text;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent ? p.accent : p.surface,
        borderRadius: BorderRadius.circular(18),
        border: accent ? null : Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color: accent ? p.onAccent.withValues(alpha: 0.9) : p.accent),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: fg)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent ? p.onAccent.withValues(alpha: 0.85) : p.text3)),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final double percent;
  final int done;
  final int total;
  const _WeeklyProgress({
    required this.percent,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = (total - done).clamp(0, total);
    return TfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly progress',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
              Text('${(percent * 100).round()}%',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: p.accent)),
            ],
          ),
          const SizedBox(height: 12),
          TfProgressBar(value: percent, height: 10),
          const SizedBox(height: 9),
          Text('$done of $total tasks completed · $left left',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text3)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _StatusRow(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TfCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 13,
      child: Row(
        children: [
          TfStatusDot(color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
          ),
          Text('$count',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
        ],
      ),
    );
  }
}
