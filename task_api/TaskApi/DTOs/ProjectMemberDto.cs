namespace TaskApi.DTOs
{
    public class ProjectMemberDto : UserDto
    {
        public string Role { get; set; } = string.Empty;
        public string Status { get; set; } = "Accepted";
        public DateTime JoinedAt { get; set; }
    }

    public class UpdateRoleRequest
    {
        public string Role { get; set; } = string.Empty;
    }
}
