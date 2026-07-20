namespace TaskApi.DTOs
{
    public class WorkspaceMemberDto : UserDto
    {
        public string Role { get; set; } = string.Empty;
        /// <summary>Pending / Accepted — workspace joins are invite-based.</summary>
        public string Status { get; set; } = "Accepted";
        public DateTime JoinedAt { get; set; }
    }
}
