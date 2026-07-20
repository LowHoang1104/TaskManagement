using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IWorkspaceService
    {
        Task<IEnumerable<WorkspaceDto>> GetWorkspacesAsync(string userId);
        Task<WorkspaceDto> CreateWorkspaceAsync(string userId, WorkspaceCreateDto request);
        Task DeleteWorkspaceAsync(string id, string actorId);
        
        Task<IEnumerable<WorkspaceMemberDto>> GetWorkspaceMembersAsync(string workspaceId, string actorId);
        Task<WorkspaceMemberDto> InviteWorkspaceMemberAsync(string workspaceId, string email, string actorId);
        Task<WorkspaceMemberDto> AcceptWorkspaceInvitationAsync(string workspaceId, string userId);
        Task<bool> DeclineWorkspaceInvitationAsync(string workspaceId, string userId);
        Task<WorkspaceMemberDto> UpdateWorkspaceMemberRoleAsync(string workspaceId, string userId, string newRole, string actorId);
        Task<bool> RemoveWorkspaceMemberAsync(string workspaceId, string userId, string actorId);
    }
}
