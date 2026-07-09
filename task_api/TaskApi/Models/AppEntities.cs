using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaskApi.Models
{
    public class User
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ICollection<WorkspaceMember> WorkspaceMembers { get; set; } = new List<WorkspaceMember>();
        public ICollection<ProjectMember> ProjectMembers { get; set; } = new List<ProjectMember>();
    }

    public class Workspace
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string OwnerId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public User Owner { get; set; } = null!;
        public ICollection<WorkspaceMember> Members { get; set; } = new List<WorkspaceMember>();
        public ICollection<Project> Projects { get; set; } = new List<Project>();
    }

    public class WorkspaceMember
    {
        public string WorkspaceId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty; // Owner, Admin, Member
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        public Workspace Workspace { get; set; } = null!;
        public User User { get; set; } = null!;
    }

    public class Project
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string WorkspaceId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = "Active"; // Active, Completed, Archived
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public Workspace Workspace { get; set; } = null!;
        public ICollection<ProjectMember> Members { get; set; } = new List<ProjectMember>();
        public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
    }

    public class ProjectMember
    {
        public string ProjectId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty; // Manager, Member, Viewer
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        public Project Project { get; set; } = null!;
        public User User { get; set; } = null!;
    }

    public class TaskItem
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string ProjectId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Status { get; set; } = "ToDo"; // ToDo, InProgress, Review, Done
        public string Priority { get; set; } = "Normal"; // Low, Normal, High, Critical
        public int Order { get; set; } = 0;
        public DateTime? Deadline { get; set; }
        public string? AssigneeId { get; set; }
        public string ReporterId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public Project Project { get; set; } = null!;
        public User? Assignee { get; set; }
        public User Reporter { get; set; } = null!;

        public ICollection<TaskTag> TaskTags { get; set; } = new List<TaskTag>();
        public ICollection<Comment> Comments { get; set; } = new List<Comment>();
        public ICollection<Attachment> Attachments { get; set; } = new List<Attachment>();
        public ICollection<ChecklistItem> ChecklistItems { get; set; } = new List<ChecklistItem>();
    }

    public class Tag
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string WorkspaceId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Color { get; set; } = "#000000";

        public Workspace Workspace { get; set; } = null!;
        public ICollection<TaskTag> TaskTags { get; set; } = new List<TaskTag>();
    }

    public class TaskTag
    {
        public string TaskId { get; set; } = string.Empty;
        public string TagId { get; set; } = string.Empty;

        public TaskItem Task { get; set; } = null!;
        public Tag Tag { get; set; } = null!;
    }

    public class Comment
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string TaskId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public TaskItem Task { get; set; } = null!;
        public User User { get; set; } = null!;
    }

    public class Attachment
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string TaskId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string FileUrl { get; set; } = string.Empty;
        public int FileSize { get; set; } = 0;
        public string UploadedById { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        public TaskItem Task { get; set; } = null!;
        public User UploadedBy { get; set; } = null!;
    }

    public class ChecklistItem
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string TaskId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public bool IsCompleted { get; set; } = false;

        public TaskItem Task { get; set; } = null!;
    }

    public class ActivityLog
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string UserId { get; set; } = string.Empty;
        public string ActionType { get; set; } = string.Empty; // e.g., "CREATE_TASK", "UPDATE_STATUS"
        public string EntityId { get; set; } = string.Empty; // ID of the affected task/project
        public string EntityType { get; set; } = string.Empty; // "Task", "Project", etc.
        public string Details { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; } = null!;
    }
}
