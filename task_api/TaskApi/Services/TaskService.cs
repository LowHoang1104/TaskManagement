using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class TaskService : ITaskService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;

        public TaskService(AppDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<TaskDto>> GetTasksAsync(string projectId)
        {
            var tasks = await _context.Tasks
                .Where(t => t.ProjectId == projectId)
                .OrderBy(t => t.Order)
                .ToListAsync();

            return _mapper.Map<IEnumerable<TaskDto>>(tasks);
        }

        public async Task<TaskDto> CreateTaskAsync(string projectId, string reporterId, TaskCreateDto request)
        {
            var task = _mapper.Map<TaskItem>(request);
            task.ProjectId = projectId;
            task.ReporterId = reporterId;
            
            // Generate order
            var maxOrder = await _context.Tasks
                .Where(t => t.ProjectId == projectId && t.Status == task.Status)
                .MaxAsync(t => (int?)t.Order) ?? 0;
            task.Order = maxOrder + 1;

            _context.Tasks.Add(task);
            await _context.SaveChangesAsync();

            return _mapper.Map<TaskDto>(task);
        }

        public async Task<TaskDto?> UpdateTaskAsync(string taskId, TaskUpdateDto request)
        {
            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) return null;

            _mapper.Map(request, task);
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return _mapper.Map<TaskDto>(task);
        }
    }
}
