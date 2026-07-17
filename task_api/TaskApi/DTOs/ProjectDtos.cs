using System.ComponentModel.DataAnnotations;

namespace TaskApi.DTOs
{
    public class ProjectDto
    {
        public string Id { get; set; } = string.Empty;
        public string WorkspaceId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = string.Empty;
        public int Progress { get; set; } = 0;
        /// <summary>Total tasks in the project (drives the "3 / 14 tasks" label).</summary>
        public int TaskCount { get; set; } = 0;
        /// <summary>Tasks with status "done".</summary>
        public int DoneTaskCount { get; set; } = 0;
        public DateTime CreatedAt { get; set; }
    }

    public class ProjectCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
