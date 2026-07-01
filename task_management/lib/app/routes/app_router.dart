import 'package:flutter/material.dart';
import '../../feature/presentation/screens/auth/splash_screen.dart';
import '../../feature/presentation/screens/auth/login_screen.dart';
import '../../feature/presentation/screens/auth/register_screen.dart';
import '../../feature/presentation/screens/workspace/workspace_list_screen.dart';
import '../../feature/presentation/screens/workspace/project_dashboard_screen.dart';
import '../../feature/presentation/screens/project/project_members_screen.dart';
import '../../feature/presentation/screens/task/task_board_screen.dart';
import '../../feature/presentation/screens/task/task_detail_screen.dart';
import '../../feature/presentation/screens/profile/profile_screen.dart';
import 'app_routes.dart';

/// Centralized route generator.
/// Each feature team adds their own case here when they create screens.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth ────────────────────────────────────────────────────────────
      case AppRoutes.splash:
        return _build(const SplashScreen(), settings);

      case AppRoutes.login:
        return _build(const LoginScreen(), settings);

      case AppRoutes.register:
        return _build(const RegisterScreen(), settings);

      // ── Workspace ────────────────────────────────────────────────────────
      case AppRoutes.workspaceList:
        return _build(const WorkspaceListScreen(), settings);

      case AppRoutes.workspaceDetail:
        // Or route it to the specific workspace detail if we make one
        return _build(const _PlaceholderScreen(title: 'Workspace Detail'), settings);

      case AppRoutes.createWorkspace:
        return _build(const _PlaceholderScreen(title: 'Create Workspace'), settings);

      // ─── Project ──────────────────────────────────────────────────────────
      case AppRoutes.projectDetail:
        return _build(const ProjectDashboardScreen(), settings);

      case AppRoutes.createProject:
        return _build(const _PlaceholderScreen(title: 'Create Project'), settings);

      case AppRoutes.projectMembers:
        return _build(const ProjectMembersScreen(), settings);

      // ── Task ─────────────────────────────────────────────────────────────
      case AppRoutes.taskBoard:
        return _build(const TaskBoardScreen(), settings);

      case AppRoutes.taskDetail:
        return _build(const TaskDetailScreen(), settings);

      case AppRoutes.createTask:
        return _build(const _PlaceholderScreen(title: 'Create Task'), settings);

      // ── Profile & Settings ───────────────────────────────────────────────
      case AppRoutes.profile:
        return _build(const ProfileScreen(), settings);

      case AppRoutes.settings:
        return _build(const _PlaceholderScreen(title: 'Settings'), settings);

      case AppRoutes.notifications:
        return _build(const _PlaceholderScreen(title: 'Notifications'), settings);

      default:
        return _build(
          const _PlaceholderScreen(title: '404 – Not Found'),
          settings,
        );
    }
  }

  static MaterialPageRoute _build(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

/// Temporary placeholder screen shown until real screens are implemented.
/// Each team member replaces the corresponding case in [AppRouter.generateRoute].
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Đang phát triển...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
