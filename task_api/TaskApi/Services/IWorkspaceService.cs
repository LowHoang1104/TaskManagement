using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IWorkspaceService
    {
        Task<IEnumerable<WorkspaceDto>> GetWorkspacesAsync(string userId);
        Task<WorkspaceDto> CreateWorkspaceAsync(string userId, WorkspaceCreateDto request);
        Task DeleteWorkspaceAsync(string id, string actorId);
    }
}
