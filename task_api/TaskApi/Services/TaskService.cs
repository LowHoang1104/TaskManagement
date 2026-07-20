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
                .Include(t => t.Assignee)
                .Include(t => t.Reporter)
                .Where(t => t.ProjectId == projectId)
                .OrderBy(t => t.Order)
                .ToListAsync();

            // Load every dependency edge touching these tasks once, then derive
            // each task's relations (blocked_by / blocking / related) in memory.
            var taskIds = tasks.Select(t => t.Id).ToList();
            var edges = await _context.Set<TaskDependency>()
                .Include(d => d.PredecessorTask)
                .Include(d => d.SuccessorTask)
                .Where(d => taskIds.Contains(d.PredecessorTaskId) ||
                            taskIds.Contains(d.SuccessorTaskId))
                .ToListAsync();

            var dtos = _mapper.Map<List<TaskDto>>(tasks);
            foreach (var dto in dtos)
            {
                dto.Relations = BuildRelations(edges, dto.Id);
            }
            return dtos;
        }

        /// Derives a task's relations from the given dependency edges, seen from
        /// that task's point of view. "blocked_by"/"blocking" are the two ends of
        /// the same enforcing (FS) edge; "related" edges never enforce ordering.
        private static List<TaskRelationDto> BuildRelations(
            List<TaskDependency> edges, string taskId)
        {
            var relations = new List<TaskRelationDto>();
            foreach (var e in edges)
            {
                var isRelated = string.Equals(e.DependencyType, "Related",
                    StringComparison.OrdinalIgnoreCase);
                if (e.SuccessorTaskId == taskId)
                {
                    relations.Add(new TaskRelationDto
                    {
                        Id = e.Id,
                        Kind = isRelated ? "related" : "blocked_by",
                        TaskId = e.PredecessorTaskId,
                        TaskTitle = e.PredecessorTask?.Title ?? string.Empty,
                        TaskStatus = e.PredecessorTask?.Status ?? string.Empty,
                    });
                }
                else if (e.PredecessorTaskId == taskId)
                {
                    relations.Add(new TaskRelationDto
                    {
                        Id = e.Id,
                        Kind = isRelated ? "related" : "blocking",
                        TaskId = e.SuccessorTaskId,
                        TaskTitle = e.SuccessorTask?.Title ?? string.Empty,
                        TaskStatus = e.SuccessorTask?.Status ?? string.Empty,
                    });
                }
            }
            return relations;
        }

        private async Task<List<TaskRelationDto>> LoadRelationsAsync(string taskId)
        {
            var edges = await _context.Set<TaskDependency>()
                .Include(d => d.PredecessorTask)
                .Include(d => d.SuccessorTask)
                .Where(d => d.PredecessorTaskId == taskId || d.SuccessorTaskId == taskId)
                .ToListAsync();
            return BuildRelations(edges, taskId);
        }

        private async Task EnsureCanManageTaskAsync(string taskId, string actorId)
        {
            var task = await _context.Tasks.FindAsync(taskId);
            if (task == null) throw new Exception("Task not found");

            var member = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(m => m.ProjectId == task.ProjectId && m.UserId == actorId);
            if (member == null || (member.Role != "Owner" && member.Role != "Admin"))
            {
                throw new UnauthorizedAccessException(
                    "Only Owner/Admin can change a task's relationships.");
            }
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
            
            if (task.AssigneeId != null && string.Equals(task.Status, "todo", StringComparison.OrdinalIgnoreCase))
            {
                task.Status = "InProgress";
            }
            
            // Generate order
            var maxOrder = await _context.Tasks
                .Where(t => t.ProjectId == projectId && t.Status == task.Status)
                .MaxAsync(t => (int?)t.Order) ?? 0;
            task.Order = maxOrder + 1;

            _context.Tasks.Add(task);
            await _context.SaveChangesAsync();

            await _context.Entry(task).Reference(t => t.Reporter).LoadAsync();
            if (task.AssigneeId != null) await _context.Entry(task).Reference(t => t.Assignee).LoadAsync();

            var createdDto = _mapper.Map<TaskDto>(task);
            createdDto.Relations = await LoadRelationsAsync(task.Id);
            return createdDto;
        }

        public async Task<TaskDto> UpdateTaskAsync(string taskId, TaskUpdateDto request, string actorId)
        {
            var task = await _context.Tasks
                .Include(t => t.Assignee)
                .Include(t => t.Reporter)
                .FirstOrDefaultAsync(t => t.Id == taskId);
            if (task == null) throw new Exception("Task not found");

            var member = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(m => m.ProjectId == task.ProjectId && m.UserId == actorId);

            if (member == null)
            {
                throw new UnauthorizedAccessException("You are not a member of this project.");
            }

            var isManager = member.Role == "Owner" || member.Role == "Admin";

            // Setting a deadline or (re)assigning a task is a manager action.
            // Members may still move a task's status, edit title/description, etc.
            if (request.Deadline != null && request.Deadline != task.Deadline && !isManager)
            {
                throw new UnauthorizedAccessException("Only Owner/Admin can change the deadline.");
            }

            if (!isManager)
            {
                if (request.AssigneeId != null && request.AssigneeId != task.AssigneeId)
                {
                    throw new UnauthorizedAccessException("Only Owner/Admin can assign a task.");
                }
                request.AssigneeId = task.AssigneeId; // Prevent unassigning
            }

            if (isManager && !string.IsNullOrEmpty(request.AssigneeId) && request.AssigneeId != task.AssigneeId)
            {
                if (string.Equals(task.Status, "todo", StringComparison.OrdinalIgnoreCase))
                {
                    if (request.Status == null || string.Equals(request.Status, "todo", StringComparison.OrdinalIgnoreCase))
                    {
                        request.Status = "InProgress";
                    }
                }
            }

            // Status transition rules.
            if (request.Status != null &&
                !string.Equals(request.Status, task.Status, StringComparison.OrdinalIgnoreCase))
            {
                var newStatus = request.Status.Trim().ToLowerInvariant();
                var currentStatus = task.Status.Trim().ToLowerInvariant();

                if (!isManager)
                {
                    if (task.AssigneeId != actorId)
                    {
                        throw new UnauthorizedAccessException("You can only move tasks assigned to you.");
                    }

                    // A finished task is locked: members can no longer touch it.
                    if (currentStatus == "done")
                    {
                        throw new UnauthorizedAccessException(
                            "This task is Done — only Owner/Admin can change it.");
                    }
                    if (newStatus == "done")
                    {
                        throw new UnauthorizedAccessException(
                            "Only Owner/Admin can move a task to Done.");
                    }
                    
                    if (currentStatus == "todo")
                    {
                        throw new UnauthorizedAccessException("You cannot move a task from ToDo. It must be assigned by an Admin first.");
                    }
                }

                // Dependency constraint: a task cannot be completed while a task it
                // depends on (a blocker) is not yet Done.
                if (newStatus == "done")
                {
                    var blockers = await _context.Set<TaskDependency>()
                        .Include(d => d.PredecessorTask)
                        // "Related" links never block completion — only enforcing edges do.
                        .Where(d => d.SuccessorTaskId == task.Id && d.DependencyType != "Related")
                        .ToListAsync();

                    var unfinished = blockers
                        .Where(b => b.PredecessorTask != null &&
                                    !string.Equals(b.PredecessorTask.Status, "done",
                                        StringComparison.OrdinalIgnoreCase))
                        .Select(b => b.PredecessorTask.Title)
                        .ToList();

                    if (unfinished.Count > 0)
                    {
                        throw new InvalidOperationException(
                            "Can't complete: some blocking tasks aren't Done yet — " +
                            string.Join(", ", unfinished));
                    }
                }
            }

            _mapper.Map(request, task);
            
            if (request.AssigneeId == "")
            {
                task.AssigneeId = null;
            }

            task.UpdatedAt = DateTime.UtcNow;

            // Stamp/clear the completion time so "done this week" reflects when a
            // task was actually finished, not merely last edited.
            var isDone = string.Equals(task.Status, "done",
                StringComparison.OrdinalIgnoreCase);
            if (isDone && task.CompletedAt == null)
            {
                task.CompletedAt = DateTime.UtcNow;
            }
            else if (!isDone)
            {
                task.CompletedAt = null;
            }

            await _context.SaveChangesAsync();

            await _context.Entry(task).Reference(t => t.Assignee).LoadAsync();

            var updatedDto = _mapper.Map<TaskDto>(task);
            updatedDto.Relations = await LoadRelationsAsync(task.Id);
            return updatedDto;
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

        public async Task SetTaskDependencyAsync(string successorId, string predecessorId, string dependencyType, string actorId)
        {
            if (successorId == predecessorId)
            {
                throw new Exception("Task cannot depend on itself.");
            }

            await EnsureCanManageTaskAsync(successorId, actorId);

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

            var isRelated = string.Equals(dependencyType, "Related", StringComparison.OrdinalIgnoreCase);

            var reverseDep = await _context.Set<TaskDependency>()
                .AnyAsync(d => d.SuccessorTaskId == predecessorId && d.PredecessorTaskId == successorId);
            if (reverseDep && isRelated)
            {
                throw new Exception("These two tasks are already linked.");
            }

            if (!isRelated)
            {
                var succTask = await _context.Tasks.FindAsync(successorId);
                if (succTask != null)
                {
                    var projId = succTask.ProjectId;
                    var allEdges = await _context.Set<TaskDependency>()
                        .Include(d => d.SuccessorTask)
                        .Where(d => d.SuccessorTask.ProjectId == projId && d.DependencyType != "Related")
                        .ToListAsync();

                    var adj = new Dictionary<string, List<string>>();
                    foreach (var edge in allEdges)
                    {
                        if (!adj.ContainsKey(edge.PredecessorTaskId))
                            adj[edge.PredecessorTaskId] = new List<string>();
                        adj[edge.PredecessorTaskId].Add(edge.SuccessorTaskId);
                    }

                    var visited = new HashSet<string>();
                    var queue = new Queue<string>();
                    queue.Enqueue(successorId);
                    visited.Add(successorId);

                    while (queue.Count > 0)
                    {
                        var curr = queue.Dequeue();
                        if (curr == predecessorId)
                        {
                            throw new Exception("Circular dependency detected. This would create a loop.");
                        }

                        if (adj.ContainsKey(curr))
                        {
                            foreach (var next in adj[curr])
                            {
                                if (!visited.Contains(next))
                                {
                                    visited.Add(next);
                                    queue.Enqueue(next);
                                }
                            }
                        }
                    }
                }
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

        public async Task RemoveTaskDependencyAsync(string dependencyId, string actorId)
        {
            var dep = await _context.Set<TaskDependency>()
                .FirstOrDefaultAsync(d => d.Id == dependencyId);
            if (dep == null) throw new Exception("Relationship not found");

            await EnsureCanManageTaskAsync(dep.SuccessorTaskId, actorId);

            _context.Set<TaskDependency>().Remove(dep);
            await _context.SaveChangesAsync();
        }
    }
}
