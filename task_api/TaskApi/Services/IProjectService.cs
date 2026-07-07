using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IProjectService
    {
        Task<IEnumerable<ProjectDto>> GetProjectsAsync(string workspaceId);
        Task<ProjectDto> CreateProjectAsync(string workspaceId, ProjectCreateDto request);
    }
}
