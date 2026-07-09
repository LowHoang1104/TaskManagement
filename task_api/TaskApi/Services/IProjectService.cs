using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IProjectService
    {
        Task<IEnumerable<ProjectDto>> GetProjectsAsync(string workspaceId, string userId);
        Task<ProjectDto> CreateProjectAsync(string workspaceId, string userId, ProjectCreateDto request);
        Task DeleteProjectAsync(string id, string actorId);
        Task<IEnumerable<ProjectMemberDto>> GetProjectMembersAsync(string projectId);
        Task<ProjectMemberDto> AddProjectMemberAsync(string projectId, string email, string actorId);
        Task<ProjectMemberDto> UpdateProjectMemberRoleAsync(string projectId, string userId, string newRole, string actorId);
        Task<ProjectMemberDto> AcceptProjectInvitationAsync(string projectId, string actorId);
        Task<bool> DeclineProjectInvitationAsync(string projectId, string actorId);
        Task<bool> LeaveProjectAsync(string projectId, string actorId);
    }
}
