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
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            try
            {
                var task = await _taskService.UpdateTaskAsync(id, request, userId);
                return Ok(task);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTask(string id)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                await _taskService.DeleteTaskAsync(id, actorId);
                return Ok(new { message = "Task deleted." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("~/api/tasks/{id}/dependencies")]
        public async Task<IActionResult> GetTaskDependencies(string id)
        {
            try
            {
                var deps = await _taskService.GetTaskDependenciesAsync(id);
                return Ok(deps);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("~/api/tasks/{id}/dependencies")]
        public async Task<IActionResult> SetTaskDependency(string id, [FromBody] SetTaskDependencyRequest request)
        {
            try
            {
                await _taskService.SetTaskDependencyAsync(id, request.PredecessorTaskId, request.DependencyType);
                return Ok(new { message = "Dependency updated successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
