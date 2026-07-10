using System.ComponentModel.DataAnnotations;

namespace TaskApi.DTOs
{
    public class TaskDto
    {
        public string Id { get; set; } = string.Empty;
        public string ProjectId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Priority { get; set; } = string.Empty;
        public int Order { get; set; }
        public DateTime? Deadline { get; set; }
        public string? AssigneeId { get; set; }
        public string ReporterId { get; set; } = string.Empty;
        public string? AssigneeName { get; set; }
        public string? ReporterName { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<TaskDependencyDto> Dependencies { get; set; } = new();
    }

    public class TaskCreateDto
    {
        [Required]
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = "ToDo";
        public string Priority { get; set; } = "Normal";
        public DateTime? Deadline { get; set; }
        public string? AssigneeId { get; set; }
    }

    public class TaskUpdateDto
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Status { get; set; }
        public string? Priority { get; set; }
        public DateTime? Deadline { get; set; }
        public string? AssigneeId { get; set; }
        public int? Order { get; set; }
    }
}
