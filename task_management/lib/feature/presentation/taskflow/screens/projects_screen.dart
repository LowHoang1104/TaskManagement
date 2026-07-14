import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../domain/entities/project_entity.dart';
import '../../providers/project_provider.dart';
import '../../providers/workspace_provider.dart';
import '../taskflow_providers.dart';
import '../tf_utils.dart';
import '../widgets/tf_widgets.dart';
import 'kanban_board_screen.dart';

/// Projects — redesigned UI from `TaskFlow.dc.html` (02 — Home), wired to the
/// workspace + project providers.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  static const _glyphs = <IconData>[
    Icons.rocket_launch_rounded,
    Icons.smartphone_rounded,
    Icons.campaign_rounded,
    Icons.dashboard_customize_rounded,
    Icons.palette_rounded,
    Icons.bug_report_rounded,
    Icons.layers_rounded,
    Icons.bolt_rounded,
  ];
  static IconData _glyphFor(String key) =>
      _glyphs[key.hashCode.abs() % _glyphs.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final workspaceState = ref.watch(workspaceNotifierProvider);
    final workspace = ref.watch(currentWorkspaceProvider);

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          color: p.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Projects',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: p.text)),
                  Icon(Icons.search_rounded, size: 24, color: p.text2),
                ],
              ),
              const SizedBox(height: 14),
              _WorkspaceSelector(
                name: workspace?.name ?? 'No workspace',
                onTap: () => _pickWorkspace(context, ref),
              ),
            ],
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: p.surface2,
            child: workspace == null
                ? _NoWorkspace(
                    loading: workspaceState.isLoading,
                    error: workspaceState.error,
                    onCreate: () => _createWorkspace(context, ref),
                  )
                : _ProjectList(
                    workspaceId: workspace.id,
                    workspaceName: workspace.name,
                    glyphFor: _glyphFor,
                  ),
          ),
        ),
      ],
    );
  }

  void _pickWorkspace(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final workspaces = ref.watch(workspaceNotifierProvider).workspaces;
          final current = ref.watch(currentWorkspaceProvider);
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
                        color: p.surface3, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Workspaces',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
                const SizedBox(height: 12),
                for (final w in workspaces)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(selectedWorkspaceIdProvider.notifier).state = w.id;
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: Text(
                                w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: p.onAccent)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(w.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: p.text)),
                          ),
                          if (current?.id == w.id)
                            Icon(Icons.check_rounded, size: 20, color: p.accent),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _CreateRow(onTap: () {
                  Navigator.pop(context);
                  _createWorkspace(context, ref);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _createWorkspace(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('New workspace',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: p.text, fontSize: 18)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Workspace name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .createWorkspace(name, '');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSelector extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _WorkspaceSelector({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: p.accent, borderRadius: BorderRadius.circular(7)),
              alignment: Alignment.center,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.onAccent)),
            ),
            const SizedBox(width: 9),
            Text(name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18, color: p.text3),
          ],
        ),
      ),
    );
  }
}

class _ProjectList extends ConsumerWidget {
  final String workspaceId;
  final String workspaceName;
  final IconData Function(String) glyphFor;
  const _ProjectList({
    required this.workspaceId,
    required this.workspaceName,
    required this.glyphFor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectNotifierProvider(workspaceId));

    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.projects.isEmpty) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load projects',
        subtitle: state.error!,
      );
    }
    if (state.projects.isEmpty) {
      return _CenteredMessage(
        icon: Icons.folder_open_rounded,
        title: 'No projects yet',
        subtitle: 'Tap the + button to create your first project.',
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(projectNotifierProvider(workspaceId).notifier).fetchProjects(workspaceId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        itemCount: state.projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final project = state.projects[i];
          return _ProjectCard(
            project: project,
            icon: glyphFor(project.id),
            iconColor: avatarColorFor(project.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KanbanBoardScreen(
                  projectId: project.id,
                  projectName: project.name,
                  workspaceId: workspaceId,
                  workspaceName: workspaceName,
                ),
              ),
            ),
            onLongPress: () => _projectActions(context, ref, project),
          );
        },
      ),
    );
  }

  void _projectActions(BuildContext context, WidgetRef ref, ProjectEntity project) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                final ok = await ref
                    .read(projectNotifierProvider(workspaceId).notifier)
                    .deleteProject(workspaceId, project.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete project'), backgroundColor: p.danger),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 20, color: p.danger),
                  const SizedBox(width: 12),
                  Text('Delete project',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.danger)),
                ]),
              ),
            ),
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(projectNotifierProvider(workspaceId).notifier)
                    .leaveProject(project.id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Icon(Icons.exit_to_app_rounded, size: 20, color: p.warning),
                  const SizedBox(width: 12),
                  Text('Leave project',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.warning)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _ProjectCard({
    required this.project,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = project.progress >= 100;
    return GestureDetector(
      onLongPress: onLongPress,
      child: TfCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TfIconBadge(icon: icon, color: iconColor, size: 34, iconSize: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                ),
                _StatusBadge(done: done),
              ],
            ),
            if ((project.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: p.text3)),
            ],
            const SizedBox(height: 14),
            TfProgressBar(
                value: project.progress / 100.0,
                color: done ? p.success : p.accent),
            const SizedBox(height: 10),
            Text('${project.progress}% complete',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: p.text3)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool done;
  const _StatusBadge({required this.done});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = done ? p.success : p.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.tint(color, 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(done ? 'DONE' : 'ACTIVE',
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color)),
    );
  }
}

class _CreateRow extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.border2, width: 1.5),
            ),
            child: Icon(Icons.add_rounded, size: 18, color: p.text3),
          ),
          const SizedBox(width: 12),
          Text('New workspace',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: p.accent)),
        ]),
      ),
    );
  }
}

class _NoWorkspace extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onCreate;
  const _NoWorkspace(
      {required this.loading, required this.error, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspaces_rounded, size: 56, color: p.text3),
            const SizedBox(height: 16),
            Text(error == null ? 'No workspace yet' : 'Could not load workspaces',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 6),
            Text(error ?? 'Create a workspace to start adding projects.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: p.text3)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TfPrimaryButton(
                  label: 'New workspace',
                  icon: Icons.add_rounded,
                  onTap: onCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CenteredMessage(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: p.text3),
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
