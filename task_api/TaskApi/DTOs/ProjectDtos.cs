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
        public DateTime CreatedAt { get; set; }
    }

    public class ProjectCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
