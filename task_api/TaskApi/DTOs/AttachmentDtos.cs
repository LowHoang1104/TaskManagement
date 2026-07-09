using System;

namespace TaskApi.DTOs
{
    public class AttachmentDto
    {
        public string Id { get; set; } = string.Empty;
        public string TaskId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string FileUrl { get; set; } = string.Empty;
        public int FileSize { get; set; }
        public string UploadedById { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; }

        public string UploaderFullName { get; set; } = string.Empty;
    }
}
