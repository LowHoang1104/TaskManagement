/// String constants: app name, error messages, labels.
class AppStrings {
  AppStrings._();

  static const String appName = 'TaskFlow';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = 'Sign in';
  static const String register = 'Sign up';
  static const String logout = 'Sign out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full name';
  static const String forgotPassword = 'Forgot password?';

  // ─── Common ───────────────────────────────────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String noData = 'No data';
  static const String success = 'Success';

  // ─── Error Messages ───────────────────────────────────────────────────────
  static const String errorNetwork = 'No internet connection. Please try again.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorUnauthorized = 'Your session has expired. Please sign in again.';
  static const String errorUnexpected = 'Something went wrong. Please try again.';

  // ─── Validation Messages ─────────────────────────────────────────────────
  static const String validationRequired = 'This field is required.';
  static const String validationEmail = 'Invalid email address.';
  static const String validationPasswordMin = 'Password must be at least 6 characters.';

  // ─── Workspace & Project ─────────────────────────────────────────────────
  static const String workspace = 'Workspace';
  static const String project = 'Project';
  static const String createWorkspace = 'Create workspace';
  static const String createProject = 'Create project';

  // ─── Task ─────────────────────────────────────────────────────────────────
  static const String task = 'Task';
  static const String createTask = 'Create task';
  static const String assignee = 'Assignee';
  static const String reporter = 'Reporter';
  static const String reviewer = 'Reviewer';
  static const String deadline = 'Deadline';
  static const String status = 'Status';
  static const String priority = 'Priority';
  static const String comment = 'Comment';
  static const String checklist = 'Checklist';
  static const String attachment = 'Attachment';

  // ─── Task Statuses ───────────────────────────────────────────────────────
  static const String statusTodo = 'To Do';
  static const String statusDoing = 'In Progress';
  static const String statusReview = 'Review';
  static const String statusDone = 'Done';

  // ─── Task Priorities ─────────────────────────────────────────────────────
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Normal';
  static const String priorityHigh = 'High';
  static const String priorityCritical = 'Critical';
}
