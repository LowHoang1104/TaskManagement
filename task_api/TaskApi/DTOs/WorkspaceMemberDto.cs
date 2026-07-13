namespace TaskApi.DTOs
{
    public class WorkspaceMemberDto : UserDto
    {
        public string Role { get; set; } = string.Empty;
        public DateTime JoinedAt { get; set; }
    }
}
