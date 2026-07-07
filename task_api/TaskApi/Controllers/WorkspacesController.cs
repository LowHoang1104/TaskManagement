using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TaskApi.DTOs;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class WorkspacesController : ControllerBase
    {
        private readonly IWorkspaceService _workspaceService;

        public WorkspacesController(IWorkspaceService workspaceService)
        {
            _workspaceService = workspaceService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

        [HttpGet]
        public async Task<IActionResult> GetWorkspaces()
        {
            var workspaces = await _workspaceService.GetWorkspacesAsync(GetUserId());
            return Ok(workspaces);
        }

        [HttpPost]
        public async Task<IActionResult> CreateWorkspace(WorkspaceCreateDto request)
        {
            var workspace = await _workspaceService.CreateWorkspaceAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetWorkspaces), new { id = workspace.Id }, workspace);
        }
    }
}
