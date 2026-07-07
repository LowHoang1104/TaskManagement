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
            var projects = await _projectService.GetProjectsAsync(workspaceId);
            return Ok(projects);
        }

        [HttpPost]
        public async Task<IActionResult> CreateProject(string workspaceId, ProjectCreateDto request)
        {
            var project = await _projectService.CreateProjectAsync(workspaceId, request);
            return CreatedAtAction(nameof(GetProjects), new { workspaceId = workspaceId, id = project.Id }, project);
        }
    }
}
