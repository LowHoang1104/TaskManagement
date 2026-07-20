/// All named route constants.
/// Usage: Navigator.pushNamed(context, AppRoutes.login)
class AppRoutes {
  AppRoutes._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';

  // ─── Home shell (redesigned TaskFlow) ─────────────────────────────────────
  static const String home = '/home';

  // ─── Workspace ───────────────────────────────────────────────────────────
  static const String workspaceList = '/workspaces';
  static const String workspaceDetail = '/workspaces/detail';
  static const String createWorkspace = '/workspaces/create';
  static const String workspaceMembers = '/workspaces/members';

  // ─── Project ──────────────────────────────────────────────────────────────
  static const String projectDetail = '/projects/detail';
  static const String createProject = '/projects/create';
  static const String projectMembers = '/projects/members';

  // ─── Task ─────────────────────────────────────────────────────────────────
  static const String taskBoard = '/tasks/board';
  static const String taskDetail = '/tasks/detail';
  static const String createTask = '/tasks/create';

  // ─── Profile & Settings ──────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';

  // ─── Notifications & Analytics ──────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
}
