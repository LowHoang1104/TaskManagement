namespace TaskApi.DTOs
{
    public class TaskDependencyDto
    {
        public string Id { get; set; } = string.Empty;
        public string PredecessorTaskId { get; set; } = string.Empty;
        public string SuccessorTaskId { get; set; } = string.Empty;
        public string DependencyType { get; set; } = string.Empty; // FS (blocking) | Related

        public string PredecessorTaskTitle { get; set; } = string.Empty;
    }

    /// <summary>
    /// A task relationship seen from one task's point of view. The intuitive
    /// model used by the app (à la Jira / Linear / ClickUp):
    /// - "blocked_by": this task waits for <see cref="TaskId"/> to finish.
    /// - "blocking":   this task must finish before <see cref="TaskId"/>.
    /// - "related":    linked, but no ordering is enforced.
    /// "blocked_by" and "blocking" are the two ends of the same FS edge.
    /// </summary>
    public class TaskRelationDto
    {
        public string Id { get; set; } = string.Empty; // dependency row id
        public string Kind { get; set; } = string.Empty; // blocked_by | blocking | related
        public string TaskId { get; set; } = string.Empty; // the other task
        public string TaskTitle { get; set; } = string.Empty;
        public string TaskStatus { get; set; } = string.Empty;
    }

    public class SetTaskDependencyRequest
    {
        public string PredecessorTaskId { get; set; } = string.Empty;
        public string DependencyType { get; set; } = string.Empty; // "FS" | "Related" | "None"
    }
}
