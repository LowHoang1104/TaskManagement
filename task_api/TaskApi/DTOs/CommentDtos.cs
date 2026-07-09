using System;
using System.ComponentModel.DataAnnotations;

namespace TaskApi.DTOs
{
    public class CommentDto
    {
        public string Id { get; set; } = string.Empty;
        public string TaskId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Include user details directly for convenience
        public string UserFullName { get; set; } = string.Empty;
        public string? UserAvatarUrl { get; set; }
    }

    public class CommentCreateDto
    {
        [Required]
        public string Content { get; set; } = string.Empty;
    }
}
