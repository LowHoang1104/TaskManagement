using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Threading.Tasks;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/tasks/{taskId}/[controller]")]
    public class AttachmentsController : ControllerBase
    {
        private readonly IAttachmentService _attachmentService;
        private readonly IWebHostEnvironment _env;

        public AttachmentsController(IAttachmentService attachmentService, IWebHostEnvironment env)
        {
            _attachmentService = attachmentService;
            _env = env;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

        [HttpGet]
        public async Task<IActionResult> GetAttachments(string taskId)
        {
            var attachments = await _attachmentService.GetAttachmentsAsync(taskId);
            return Ok(attachments);
        }

        [HttpPost]
        public async Task<IActionResult> UploadAttachment(string taskId, IFormFile file)
        {
            var webRootPath = _env.WebRootPath;
            if (string.IsNullOrWhiteSpace(webRootPath))
            {
                webRootPath = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "wwwroot");
            }

            var requestScheme = Request.Scheme;
            var requestHost = Request.Host.Value;

            var attachment = await _attachmentService.UploadAttachmentAsync(taskId, GetUserId(), file, webRootPath, requestScheme, requestHost);
            return Ok(attachment);
        }

        [HttpDelete("{attachmentId}")]
        public async Task<IActionResult> DeleteAttachment(string taskId, string attachmentId)
        {
            var webRootPath = _env.WebRootPath;
            if (string.IsNullOrWhiteSpace(webRootPath))
            {
                webRootPath = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "wwwroot");
            }

            try
            {
                await _attachmentService.DeleteAttachmentAsync(attachmentId, GetUserId(), webRootPath);
                return Ok(new { message = "Attachment deleted." });
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
