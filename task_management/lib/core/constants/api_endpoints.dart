/// Base URL for the API.
const String kBaseUrl = 'http://127.0.0.1:5058/api';

/// Timeout durations (in seconds).
const int kConnectTimeout = 15;
const int kReceiveTimeout = 15;
const int kSendTimeout = 15;

/// Auth endpoints
class AuthEndpoints {
  AuthEndpoints._();
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
}

/// User endpoints
class UserEndpoints {
  UserEndpoints._();
  static const String dashboard = '/dashboard/me';
}

/// Workspace endpoints
class WorkspaceEndpoints {
  WorkspaceEndpoints._();
  static const String base = '/workspaces';
  static String byId(String id) => '/workspaces/$id';
  static String members(String id) => '/workspaces/$id/members';
  static String delete(String id) => '/workspaces/$id';
}

/// Project endpoints
class ProjectEndpoints {
  ProjectEndpoints._();
  static const String base = '/projects';
  static String byId(String id) => '/projects/$id';
  static String byWorkspace(String workspaceId) =>
      '/workspaces/$workspaceId/projects';
  static String members(String id) => '/projects/$id/members';
  static String delete(String workspaceId, String id) => '/workspaces/$workspaceId/projects/$id';
}

/// Task endpoints
class TaskEndpoints {
  TaskEndpoints._();
  static const String base = '/tasks';
  static String byId(String id) => '/tasks/$id';
  static String byProject(String projectId) => '/projects/$projectId/tasks';
  static String delete(String projectId, String id) => '/projects/$projectId/tasks/$id';
  static String comments(String taskId) => '/tasks/$taskId/comments';
  static String checklists(String taskId) => '/tasks/$taskId/checklists';
  static String attachments(String taskId) => '/tasks/$taskId/attachments';
  static String activityLogs(String taskId) => '/tasks/$taskId/activity-logs';
  static String reviewHistory(String taskId) => '/tasks/$taskId/reviews';
}

/// Notification endpoints
class NotificationEndpoints {
  NotificationEndpoints._();
  static const String base = '/notifications';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';
}
