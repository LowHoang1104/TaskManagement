using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaskApi.DTOs;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/workspaces/{workspaceId}/[controller]")]
    public class ProjectsController : ControllerBase
    {
        private readonly IProjectService _projectService;

        public ProjectsController(IProjectService projectService)
        {
            _projectService = projectService;
        }

        [HttpGet]
        public async Task<IActionResult> GetProjects(string workspaceId)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var projects = await _projectService.GetProjectsAsync(workspaceId, userId);
            return Ok(projects);
        }

        [HttpPost]
        public async Task<IActionResult> CreateProject(string workspaceId, ProjectCreateDto request)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var project = await _projectService.CreateProjectAsync(workspaceId, userId, request);
            return CreatedAtAction(nameof(GetProjects), new { workspaceId = workspaceId, id = project.Id }, project);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProject(string workspaceId, string id)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                await _projectService.DeleteProjectAsync(id, userId!);
                return Ok(new { message = "Project deleted successfully." });
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
    }
}
