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
        [HttpGet("{id}/members")]
        public async Task<IActionResult> GetWorkspaceMembers(string id)
        {
            try
            {
                var members = await _workspaceService.GetWorkspaceMembersAsync(id, GetUserId());
                return Ok(members);
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

        [HttpPost("{id}/members")]
        public async Task<IActionResult> InviteWorkspaceMember(string id, [FromBody] InviteMemberRequest request)
        {
            try
            {
                var member = await _workspaceService.InviteWorkspaceMemberAsync(id, request.Email, GetUserId());
                return Ok(member);
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

        [HttpPost("{id}/accept")]
        public async Task<IActionResult> AcceptWorkspaceInvitation(string id)
        {
            try
            {
                var member = await _workspaceService.AcceptWorkspaceInvitationAsync(id, GetUserId());
                return Ok(member);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/decline")]
        public async Task<IActionResult> DeclineWorkspaceInvitation(string id)
        {
            try
            {
                await _workspaceService.DeclineWorkspaceInvitationAsync(id, GetUserId());
                return Ok(new { message = "Invitation declined." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}/members/{userId}/role")]
        public async Task<IActionResult> UpdateWorkspaceMemberRole(string id, string userId, [FromBody] UpdateRoleRequest request)
        {
            try
            {
                var member = await _workspaceService.UpdateWorkspaceMemberRoleAsync(id, userId, request.Role, GetUserId());
                return Ok(member);
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

        [HttpDelete("{id}/members/{userId}")]
        public async Task<IActionResult> RemoveWorkspaceMember(string id, string userId)
        {
            try
            {
                await _workspaceService.RemoveWorkspaceMemberAsync(id, userId, GetUserId());
                return Ok(new { message = "Member removed successfully." });
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
