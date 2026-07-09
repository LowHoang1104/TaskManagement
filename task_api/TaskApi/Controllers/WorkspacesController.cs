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

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteWorkspace(string id)
        {
            try
            {
                await _workspaceService.DeleteWorkspaceAsync(id, GetUserId());
                return Ok(new { message = "Workspace deleted successfully." });
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
