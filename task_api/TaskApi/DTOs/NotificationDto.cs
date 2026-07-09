using System;

namespace TaskApi.DTOs
{
    public class NotificationDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // Invite, Comment
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public string? RelatedId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
