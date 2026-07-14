import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../widgets/tf_widgets.dart';
import '../taskflow_providers.dart';
import 'dashboard_screen.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'notifications_screen.dart';
import 'create_project_screen.dart';

/// Root navigation shell for the redesigned TaskFlow app — hosts the four
/// primary destinations (Home / Projects / Tasks / Inbox) behind the bottom
/// navigation bar from `TaskFlow.dc.html` (02 — Home).
class TaskFlowShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const TaskFlowShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<TaskFlowShell> createState() => _TaskFlowShellState();
}

class _TaskFlowShellState extends ConsumerState<TaskFlowShell> {
  late int _index = widget.initialIndex;

  static const _items = [
    TfNavItem(Icons.grid_view_rounded, 'Home'),
    TfNavItem(Icons.folder_open_rounded, 'Projects'),
    TfNavItem(Icons.checklist_rounded, 'Tasks'),
    TfNavItem(Icons.notifications_none_rounded, 'Inbox'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            DashboardScreen(),
            ProjectsScreen(),
            TasksScreen(),
            NotificationsScreen(),
          ],
        ),
      ),
      floatingActionButton: _fab(context),
      bottomNavigationBar: TfBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget? _fab(BuildContext context) {
    final p = context.palette;
    // Only the Projects tab shows a FAB (create project). New tasks are created
    // from a project's board, which carries the required project context.
    if (_index != 1) return null;
    final workspace = ref.watch(currentWorkspaceProvider);
    if (workspace == null) return null;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProjectScreen(
            workspaceId: workspace.id,
            workspaceName: workspace.name,
          ),
        ),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, size: 28, color: p.onAccent),
      ),
    );
  }
}
