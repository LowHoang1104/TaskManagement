using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface ITaskService
    {
        Task<IEnumerable<TaskDto>> GetTasksAsync(string projectId);
        Task<TaskDto> CreateTaskAsync(string projectId, string reporterId, TaskCreateDto request);
        Task<TaskDto> UpdateTaskAsync(string id, TaskUpdateDto request, string actorId);
        Task DeleteTaskAsync(string id, string actorId);
    }
}
