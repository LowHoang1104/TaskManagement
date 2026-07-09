using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaskApi.DTOs;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/projects/{projectId}/members")]
    public class ProjectMembersController : ControllerBase
    {
        private readonly IProjectService _projectService;

        public ProjectMembersController(IProjectService projectService)
        {
            _projectService = projectService;
        }

        [HttpGet]
        public async Task<IActionResult> GetProjectMembers(string projectId)
        {
            try
            {
                var members = await _projectService.GetProjectMembersAsync(projectId);
                return Ok(members);
            }
            catch (Exception ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> InviteMember(string projectId, [FromBody] InviteMemberRequest request)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                var user = await _projectService.AddProjectMemberAsync(projectId, request.Email, actorId);
                return Ok(user);
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

        [HttpPut("{userId}/role")]
        public async Task<IActionResult> UpdateMemberRole(string projectId, string userId, [FromBody] UpdateRoleRequest request)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                var updatedMember = await _projectService.UpdateProjectMemberRoleAsync(projectId, userId, request.Role, actorId);
                return Ok(updatedMember);
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

        [HttpPut("accept")]
        public async Task<IActionResult> AcceptInvite(string projectId)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                var updatedMember = await _projectService.AcceptProjectInvitationAsync(projectId, actorId);
                return Ok(updatedMember);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("decline")]
        public async Task<IActionResult> DeclineInvite(string projectId)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                await _projectService.DeclineProjectInvitationAsync(projectId, actorId);
                return Ok(new { message = "Invitation declined." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("leave")]
        public async Task<IActionResult> LeaveProject(string projectId)
        {
            var actorId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(actorId)) return Unauthorized();

            try
            {
                await _projectService.LeaveProjectAsync(projectId, actorId);
                return Ok(new { message = "You have left the project." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }

    public class InviteMemberRequest
    {
        public string Email { get; set; } = string.Empty;
    }
}
