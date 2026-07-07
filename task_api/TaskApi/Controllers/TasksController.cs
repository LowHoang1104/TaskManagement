using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TaskApi.DTOs;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/projects/{projectId}/[controller]")]
    public class TasksController : ControllerBase
    {
        private readonly ITaskService _taskService;

        public TasksController(ITaskService taskService)
        {
            _taskService = taskService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

        [HttpGet]
        public async Task<IActionResult> GetTasks(string projectId)
        {
            var tasks = await _taskService.GetTasksAsync(projectId);
            return Ok(tasks);
        }

        [HttpPost]
        public async Task<IActionResult> CreateTask(string projectId, TaskCreateDto request)
        {
            var task = await _taskService.CreateTaskAsync(projectId, GetUserId(), request);
            return CreatedAtAction(nameof(GetTasks), new { projectId = projectId, id = task.Id }, task);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTask(string projectId, string id, TaskUpdateDto request)
        {
            var task = await _taskService.UpdateTaskAsync(id, request);
            if (task == null) return NotFound();
            return Ok(task);
        }
    }
}
