/// Role of a member within a workspace.
enum WorkspaceRole {
  owner,
  admin,
  member,
}

/// Role of a member within a project.
enum ProjectRole {
  leader,
  member,
}

/// Status of a task.
enum TaskStatus {
  todo,
  doing,
  review,
  done,
}

/// Priority level of a task.
enum TaskPriority {
  low,
  medium,
  high,
  critical,
}

/// Result of a review.
enum ReviewResult {
  approved,
  rejected,
}
