namespace TaskApi.DTOs
{
    public class TaskDependencyDto
    {
        public string Id { get; set; } = string.Empty;
        public string PredecessorTaskId { get; set; } = string.Empty;
        public string SuccessorTaskId { get; set; } = string.Empty;
        public string DependencyType { get; set; } = string.Empty; // FS, SS, FF, SF

        public string PredecessorTaskTitle { get; set; } = string.Empty;
    }

    public class SetTaskDependencyRequest
    {
        public string PredecessorTaskId { get; set; } = string.Empty;
        public string DependencyType { get; set; } = string.Empty; // FS, SS, FF, SF, or "None"
    }
}
