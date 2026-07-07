using System.ComponentModel.DataAnnotations;

namespace TaskApi.DTOs
{
    public class WorkspaceDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string OwnerId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class WorkspaceCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
