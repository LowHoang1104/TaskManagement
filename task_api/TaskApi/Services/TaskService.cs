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
                .Include(t => t.Dependencies)
                .ThenInclude(d => d.PredecessorTask)
                .Include(t => t.Assignee)
                .Include(t => t.Reporter)
                .Where(t => t.ProjectId == projectId)
                .OrderBy(t => t.Order)
                .ToListAsync();

            return _mapper.Map<IEnumerable<TaskDto>>(tasks);
        }

        public async Task<TaskDto> CreateTaskAsync(string projectId, string reporterId, TaskCreateDto request)
        {
            var projectMember = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == reporterId);

            if (projectMember == null || (projectMember.Role != "Owner" && projectMember.Role != "Admin"))
            {
                throw new UnauthorizedAccessException("Only project Admins or Owners can create tasks.");
            }

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

            await _context.Entry(task).Reference(t => t.Reporter).LoadAsync();
            if (task.AssigneeId != null) await _context.Entry(task).Reference(t => t.Assignee).LoadAsync();

            return _mapper.Map<TaskDto>(task);
        }

        public async Task<TaskDto> UpdateTaskAsync(string taskId, TaskUpdateDto request, string actorId)
        {
            var task = await _context.Tasks
                .Include(t => t.Assignee)
                .Include(t => t.Reporter)
                .FirstOrDefaultAsync(t => t.Id == taskId);
            if (task == null) throw new Exception("Task not found");

            _mapper.Map(request, task);
            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _context.Entry(task).Reference(t => t.Assignee).LoadAsync();

            return _mapper.Map<TaskDto>(task);
        }

        public async Task DeleteTaskAsync(string id, string actorId)
        {
            var task = await _context.Tasks.FindAsync(id);
            if (task == null)
            {
                throw new Exception("Task not found");
            }

            var projectMember = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(m => m.ProjectId == task.ProjectId && m.UserId == actorId);

            if (projectMember == null || (projectMember.Role != "Owner" && projectMember.Role != "Admin"))
            {
                throw new UnauthorizedAccessException("Only project Admins or Owners can delete the task.");
            }

            _context.Tasks.Remove(task);
            await _context.SaveChangesAsync();
        }

        public async Task<IEnumerable<TaskDependencyDto>> GetTaskDependenciesAsync(string taskId)
        {
            var dependencies = await _context.Set<TaskDependency>()
                .Include(d => d.PredecessorTask)
                .Where(d => d.SuccessorTaskId == taskId)
                .ToListAsync();

            return dependencies.Select(d => new TaskDependencyDto
            {
                Id = d.Id,
                PredecessorTaskId = d.PredecessorTaskId,
                SuccessorTaskId = d.SuccessorTaskId,
                DependencyType = d.DependencyType,
                PredecessorTaskTitle = d.PredecessorTask.Title
            });
        }

        public async Task SetTaskDependencyAsync(string successorId, string predecessorId, string dependencyType)
        {
            if (successorId == predecessorId)
            {
                throw new Exception("Task cannot depend on itself.");
            }

            var existingDep = await _context.Set<TaskDependency>()
                .FirstOrDefaultAsync(d => d.SuccessorTaskId == successorId && d.PredecessorTaskId == predecessorId);

            if (dependencyType == "None")
            {
                if (existingDep != null)
                {
                    _context.Set<TaskDependency>().Remove(existingDep);
                    await _context.SaveChangesAsync();
                }
                return;
            }

            var reverseDep = await _context.Set<TaskDependency>()
                .AnyAsync(d => d.SuccessorTaskId == predecessorId && d.PredecessorTaskId == successorId);

            if (reverseDep)
            {
                throw new Exception("Circular dependency detected.");
            }

            if (existingDep != null)
            {
                existingDep.DependencyType = dependencyType;
            }
            else
            {
                var newDep = new TaskDependency
                {
                    SuccessorTaskId = successorId,
                    PredecessorTaskId = predecessorId,
                    DependencyType = dependencyType
                };
                _context.Set<TaskDependency>().Add(newDep);
            }

            await _context.SaveChangesAsync();
        }
    }
}
